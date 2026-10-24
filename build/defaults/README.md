# Finding the `defaults write` behind a System Settings change

Most of System Settings is a preferences plist, and `defaults` reads all of
them. The problem is not exporting, which is one command. The problem is
that the export is tens of thousands of keys and nothing in it says which
one is "natural scrolling". The method that works is a diff.

## Method

```zsh
build/defaults/snapshot take before
# change ONE thing in System Settings
build/defaults/snapshot take after
build/defaults/snapshot last
```

The diff names the domain, the key, and the value Apple writes. Turn that
into a line in `install/macos`:

```zsh
defaults write com.apple.dock autohide -bool true
```

One change per snapshot pair. Two changes at once can land in the same
domain and the diff stops telling you which was which.

`snapshot take` captures three views. `defaults read` is every domain for
your user. `defaults -currentHost read` is the per-machine set, where
trackpad and mouse settings live. `NSGlobalDomain` is inside the first but
kept on its own because keyboard repeat and scrolling direction live there.
It also records the settings that are not preferences at all: hostnames
from `scutil`, power from `pmset`, and what `systemsetup` will report
without sudo.

## Known keys

| Setting | Domain | Key |
|---|---|---|
| Natural scrolling | `NSGlobalDomain` | `com.apple.swipescrolldirection` (bool) |
| Key repeat | `NSGlobalDomain` | `KeyRepeat`, `InitialKeyRepeat` (int) |
| Dock | `com.apple.dock` | `autohide`, `tilesize`, `orientation`, `show-recents`, `minimize-to-application` |
| Hot corners | `com.apple.dock` | `wvous-tl-corner`, `wvous-tr-corner`, `wvous-bl-corner`, `wvous-br-corner` |
| Finder | `com.apple.finder` | `ShowPathbar`, `ShowStatusBar`, `FXDefaultSearchScope`, `_FXShowPosixPathInTitle` |
| Tap to click | `com.apple.AppleMultitouchTrackpad` and, `-currentHost`, `com.apple.driver.AppleBluetoothMultitouch.trackpad` | `Clicking` |
| Screenshots folder | `com.apple.screencapture` | `location` |

These are the same names nix-darwin uses under `system.defaults`, which is
why `robbinshinds.family/workstation/profiles/desktop.nix` reads the way it
does. When the seed grows a nix-darwin role, `install/macos` moves there
line for line.

## Taking effect

Some keys apply at once. Others need the owning process restarted:
`killall Dock`, `killall Finder`, `killall SystemUIServer`. A few, such as
keyboard repeat, apply at the next login. `install/macos` should end with
the restarts it needs and say which keys want a logout.

## Not preferences

- Hostname: `scutil --set HostName`, `LocalHostName`, `ComputerName`.
- Sleep and power: `pmset`.
- Time zone, remote login, startup disk: `systemsetup`, under sudo.
- Network locations and DNS: `networksetup`.
- Privacy permissions: the TCC database. Not exportable, not writable.
- Login items: per application.

## Caveats

The diff flattens a nested plist dump into lines, which is good enough to
locate a key and read its value. It is not a plist parser. For the exact
type of a value, read it back: `defaults read-type <domain> <key>`.
