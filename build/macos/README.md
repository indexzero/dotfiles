# Capture macOS preferences with Raskin

[Raskin] captures stored macOS preferences as KDL and generates a standalone
`.macos` script for you to inspect and run on another Mac. [raskin.kdl] lists
the settings this setup cares about; it contains key names, not their values.

## Basic usage

Install the published crate, then run these commands from the dotfiles root:

```zsh
cargo install raskin --locked
raskin capture -p build/macos/raskin.kdl -o "$HOME/myprefs.kdl"
raskin generate "$HOME/myprefs.kdl" -o "$HOME/myprefs.macos"
```

Capture reads the current stored values for the selected keys, including
complete arrays and dictionaries. Missing or unsupported values are omitted;
the terminal summary reports what was captured and skipped. Add `--verbose`
for details. Existing output files are refused unless you pass `--force`.

The output paths above keep captured values outside this checkout. Back up
and transfer them with your usual tools. Read the generated `.macos` file,
then run it yourself on the destination Mac; Raskin is not needed there.

To compare machines, capture with the same preset on each and use ordinary
`diff` on the KDL files, or generate both `.macos` files and compare those.
Omitting `-p` selects the built-in `apple` preset. Other built-ins include
`desktop`, `input`, `power`, and `terminal`; `broad` includes wider app state.

## Compare Raskin captures in a Tart VM

A separate vanilla VM can supply a reference capture for narrowing a Mac's
preferences. Use the same Raskin binary and capture preset on both machines.
Prefer the same macOS release and build; record any mismatch. A VM's power,
display, and input hardware also differ from the physical Mac.

The commands below run from the dotfiles root and use the existing
[Tart wrapper](../tart/README.md). Create a separate VM directly from an
image, preserving `pristine` and any bootstrap runs. This example uses macOS
27.0; use an appropriate tag or pin the image digest for repeatable captures.
Automatic pruning is disabled. Keep the VM window open so you can log in
and see any permission prompts:

```zsh
TART_PRISTINE=ghcr.io/cirruslabs/macos-golden-gate-vanilla:27.0 \
  TART_NO_AUTO_PRUNE=true build/tart/vm new raskin-baseline
tart run raskin-baseline --no-audio --no-clipboard
```

In another host terminal, copy the installed binary and this preset. The
guest uses its existing `admin` account; there is no bootstrap or app
installation step. The SSH password is `admin`.

```zsh
raskin_comparison="$HOME/raskin-baseline-comparison"
raskin_binary="$(command -v raskin)"
mkdir -m 700 "$raskin_comparison"
build/tart/vm scp -p "$raskin_binary" raskin-baseline:~/raskin
build/tart/vm scp build/macos/raskin.kdl raskin-baseline:~/raskin-preset.kdl
build/tart/vm ssh raskin-baseline 'sw_vers; shasum -a 256 ~/raskin'
sw_vers
shasum -a 256 "$raskin_binary"
```

In the VM's Terminal, collect the baseline. This keeps permission dialogs
in the desktop session where you can respond to them:

```zsh
~/raskin capture -p ~/raskin-preset.kdl -o ~/baseline.kdl
```

After capture finishes, return to the host terminal. Copy the file before
stopping the VM, then capture this Mac with the same preset:

```zsh
build/tart/vm scp raskin-baseline:~/baseline.kdl "$raskin_comparison/baseline.kdl"
raskin capture -p build/macos/raskin.kdl -o "$raskin_comparison/host.kdl"
diff -u "$raskin_comparison/baseline.kdl" "$raskin_comparison/host.kdl"
tart stop raskin-baseline
```

`diff` exits 1 when files differ. Captures refuse to overwrite existing
files. For a built-in comparison, use the same preset on both machines:
`--preset desktop`, `--preset input`, or `--preset power`, with separate
filenames. Keep captures private: broad capture includes application state
as well as preferences.

Compare settings by domain, scope, host selector, container, key, and typed
value. Keep arrays and dictionaries intact. Equal values are candidates for
removal only when the reference is appropriate for that setting. Different
values need review, and a key absent from the VM has no observed baseline.
That absence can reflect an uninstalled app, an unstored default, different
hardware, or an unreadable source. An empty preset capture does not mean the
guest has no defaults: Raskin captures supported persisted settings, not
every effective application default. Check each capture's diagnostics as
well as its data.

Vanilla images already contain automation customizations. The [27.0 image
template] changes keyboard navigation, screen savers, sleep, screen locking,
timezone, remote access, and Safari automation. Account for those settings
when interpreting a comparison: even an equal value may match an image
customization. A baseline difference alone does not establish that the user
changed a setting. The template is source evidence to read; do not run its
provisioning commands as part of this workflow.

This workflow collects and compares files. Generated `.macos` scripts and
their commands are never executed by agents, including inside the VM.

[Raskin]: https://github.com/indexzero/raskin
[raskin.kdl]: raskin.kdl
[27.0 image template]: https://github.com/cirruslabs/macos-image-templates/blob/27/templates/vanilla-golden-gate.pkr.hcl
