# "GOTCHA"!'s

A "gotcha" is a very narrow bit of knowledge that has an enormous impact on one's productivity. In this file I document "gotchas" I encounter in everyday life

- [`xcrun` gotcha from macOS upgrades](https://stackoverflow.com/questions/41116584/error-xcode-select-error-tool-xcodebuild-requires-xcode)
  - Tree depth: 2
- [`/usr/bin/git` refuses to run: "You have not agreed to the Xcode license agreements"](#usrbingit-and-the-xcode-license)
- [A test sees `/private/var/...` where it expected `/var/...`](#var-is-a-symlink-to-privatevar)

## `/usr/bin/git` and the Xcode license

**Symptom.** Something that calls `/usr/bin/git` directly fails with:

```
You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license' from within a Terminal window to review and agree to the Xcode and Apple SDKs license.
```

Your shell's `git` works fine, because Homebrew's `/opt/homebrew/bin/git` comes first on `PATH`. Only code that hardcodes `/usr/bin/git`, or runs with a minimal `PATH`, hits it. This can cause confusing CI errors when the `git` version from `/opt/homebrew` diverges with the version from the version `Xcode` ships and one of them matches the `git` version used in remote CI containers

**Cause.** `/usr/bin/git` is not git. It is an Apple shim that forwards to the git inside the *active developer directory*, the one `xcode-select -p` prints. There are two possible directories:

| Developer directory | Path | License gate |
|---|---|---|
| Command Line Tools | `/Library/Developer/CommandLineTools` | none |
| Full Xcode | `/Applications/Xcode.app/Contents/Developer` | must accept the Xcode license |

The Homebrew installer installs the Command Line Tools when they are missing. It never touches the Xcode license. So a fresh machine works. Installing full Xcode later switches the active directory to Xcode, and from then on the shim refuses until the license is accepted.

**Diagnose.**

```sh
xcode-select -p                 # which directory the shim uses
/usr/bin/git --version          # the license message means the gate is closed
DEVELOPER_DIR=/Library/Developer/CommandLineTools /usr/bin/git --version   # works if the CLT are installed
```

**Fix.** Pick one. Both need `sudo`.

```sh
# 1. Point the shim back at the Command Line Tools. Accepts nothing.
sudo xcode-select --switch /Library/Developer/CommandLineTools

# 2. Keep full Xcode active and accept its license once.
sudo xcodebuild -license accept
```

Use 2 if you build iOS or macOS apps with `xcodebuild`, which needs full Xcode active. Otherwise 1 is the smaller change. If the Command Line Tools are missing, `xcode-select --install` reinstalls them.

**Recheck after a macOS or Xcode upgrade.** An Xcode update can ship a new license and close the gate again.

## `/var` is a symlink to `/private/var`

**Symptom.** A test passes on Linux and fails on macOS with two paths that differ only by a `/private` prefix:

```
- "/var/folders/xy/.../T/goldens-cli-NEiEbY/one.png"
+ "/private/var/folders/xy/.../T/goldens-cli-NEiEbY/one.png"
```

**Cause.** `os.tmpdir()` (and `$TMPDIR`) on macOS points under `/var/folders/...`. `/var`, `/tmp`, and `/etc` are symlinks into `/private`. Code that resolves symlinks (`realpath`, `fs.realpathSync`, `process.cwd()` after a `chdir`, `git rev-parse --show-toplevel`) reports `/private/var/...`, while code that kept the original string reports `/var/...`. Linux has no such symlink, so CI never sees it.

**Fix.** In the test, resolve the temp directory once at creation, so both sides compare resolved paths:

```ts
const dir = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'prefix-')));
```
