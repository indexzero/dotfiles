# Testing the bootstrap in a tart VM

`install/bootstrap.zsh` claims to take a blank Apple Silicon Mac to a working
setup. The only honest test is a blank Mac, and [tart] gives us one in a few
seconds per run. This directory holds the recipe and a thin wrapper, `vm`,
around the tart commands it repeats.

`tart` itself comes from `Brewfile.system`.

## Which image

Use a `vanilla` image, never `base`. Vanilla is a clean install: user `admin`,
password `admin`, SSH on, no Homebrew, no Command Line Tools. That is the
"from nothing" the script has to handle. `base` images ship Homebrew and the
CLT preinstalled, which skips the two steps most likely to break.

Pick the newest guest at or below the host's macOS. The guest never needs to
match the host exactly. Tags come from the registry:

```zsh
build/tart/vm tags            # lists ghcr.io/cirruslabs/macos-*-vanilla tags
```

## One-time: a pristine image

```zsh
build/tart/vm pristine ghcr.io/cirruslabs/macos-tahoe-vanilla:26.6.2
```

That pulls the image (about 30 GB, cached in `~/.tart/cache`), names the VM
`pristine`, and grows its disk to 120 GB before the first boot. All the
Brewfile sets plus a Nix store do not fit the default disk. tart can only
grow a disk, never shrink it, and doing it before the first boot lets the
guest expand its container as it comes up.

Never run `pristine` itself. tart has no snapshots. The pattern is a copy per
run, and a local `tart clone` is an APFS clone that takes seconds.

## Each run

Terminal one. Leave the window open: cask installers and permission dialogs
show up there, and the Command Line Tools GUI installer if `softwareupdate`
finds no label.

```zsh
build/tart/vm new run1        # clone pristine -> run1
build/tart/vm run run1        # boots it with ~/Git/indexzero/dotfiles shared read-only
```

Terminal two:

```zsh
build/tart/vm ssh run1        # password: admin
```

Inside the VM, the honest test from a branch (`main` once it has the script):

```zsh
curl -fsSL https://raw.githubusercontent.com/indexzero/dotfiles/<branch>/install/bootstrap.zsh | DOTFILES_REF=<branch> zsh 2>&1 | tee ~/bootstrap.log
```

### Edit-and-rerun without pushing

`vm run` shares the host checkout at `/Volumes/My Shared Files/dotfiles`.
The script exports `DOTFILES_REMOTE`, so the clone can come from the mount:

```zsh
DOTFILES_REMOTE="/Volumes/My Shared Files/dotfiles" DOTFILES_REF=<branch> \
  zsh "/Volumes/My Shared Files/dotfiles/install/bootstrap.zsh" 2>&1 | tee ~/bootstrap.log
```

The branch must exist in the host checkout. Worktrees share refs with the
main repo, so a branch checked out in a worktree counts. Edits on the host
show up in the VM at once, but commit them first: the clone reads committed
refs, not the working tree.

### Between runs

- Re-running inside the same VM tests idempotency and the resume path
  (`BOOTSTRAP_SKIP`, `BOOTSTRAP_ONLY`).
- A clean slate: `build/tart/vm reset run1` deletes and re-clones from
  `pristine`.
- `tart suspend run1` keeps a VM's state across host sleep.
- `tart exec` needs the guest agent, which vanilla images lack. SSH is the
  way in.

## What to watch for

- **Command Line Tools.** In a VM `softwareupdate -l` may not list the CLT
  label. The script then falls back to `xcode-select --install` and polls.
  Click through the dialog in the window.
- **sudo.** Prompts for `admin` on the SSH terminal. The script hands children
  `/dev/tty` for exactly this.
- **Casks.** Some want a password or open a GUI. The window shows them.
- **Nix.** The Determinate installer creates an APFS volume for the store.
  This works inside Virtualization.framework guests.
- **`devenv.lock`.** Generated into the clone's `workstation/` on first
  deploy. `hostdiff ingest` carries it back to the checkout.

## Disk

Each cloned VM shares blocks with `pristine` until it writes, then grows.
A full bootstrap run writes tens of GB. `tart list` shows sizes,
`tart delete <name>` reclaims a VM, and `tart prune --entries caches` drops
pulled images you no longer need.

[tart]: https://tart.run
