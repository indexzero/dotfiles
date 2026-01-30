# Spoonman: Hammerspoon Spoon Manager

## The Problem We're Solving

### macOS Spaces Rearrangement Issue

macOS Spaces (virtual desktops) have a chronic problem dating back to 2011: they rearrange themselves unpredictably, especially after laptop sleep/wake cycles. The user has 5-6 spaces with multiple windows from the same 3 apps spread across them, and experiences reorganization on sleep/wake.

**Root causes identified:**
- Full-screen apps trigger rearrangement
- Default "Automatically rearrange Spaces based on most recent use" setting
- Sleep/wake cycles
- Display configuration changes (external monitors)

**Standard solutions that don't fully work:**
- Disable auto-rearrange in System Preferences (helps but doesn't solve)
- Avoid full-screen apps
- Assign apps to specific desktops (only works at app level, not window level)
- Direct keyboard shortcuts (Ctrl+1, Ctrl+2, etc.) instead of swipe gestures
- Reset com.apple.spaces.plist (stores ephemeral window IDs, not reliable)

### Window Managers Evaluated

| Tool | Approach | Status |
|------|----------|--------|
| **Yabai** | Tiling WM, requires SIP disabling | BROKEN on Sequoia, even with SIP disabled |
| **AeroSpace** | i3-inspired, emulates workspaces | No window-level support, app-level only |
| **Amethyst** | xmonad-style tiling | Doesn't solve space persistence |
| **FlashSpace** | Space management | App-level only |
| **Rectangle** | Window snapping/layouts | Layout-only, no space management |

### The Sequoia Breaking Change

**macOS 15.0 Sequoia broke `hs.spaces.moveWindowToSpace`** - the function returns true but doesn't actually move windows. This affects ALL Hammerspoon-based solutions. 

- Hammerspoon GitHub Issue #3698 (21+ reactions, no fix)
- Yabai also broken: Issues #2380, #2425, #2441, #2469, #2500, #2591
- Apple changed the private `CGSMoveWindowToSpace` API with no public alternative

### Hammerspoon Solutions Investigated

**restore-spaces** (github.com/tplobo/restore-spaces)
- Saves/restores window-to-space organization
- BROKEN on Sequoia - depends on moveWindowToSpace

**SpacePigeon** (github.com/louivers/spacepigeon)
- GUI wrapper around Hammerspoon for workspace definitions
- BROKEN on Sequoia - depends on moveWindowToSpace

**VirtualSpaces.spoon** (github.com/brennovich/VirtualSpaces.spoon)
- Creates logical workspaces on single macOS desktop using two native Spaces
- BROKEN on Sequoia - heavily relies on moveWindowToSpace

**EnhancedSpaces.spoon** (github.com/franzbu/EnhancedSpaces.spoon) ⭐ SELECTED
- WORKS ON SEQUOIA - built specifically to bypass the broken API
- Creates "mSpaces" (virtual spaces) via window visibility management
- 1,146 commits, mature and actively maintained
- Features: grid overview, sticky windows, window swapping, menubar controls, state persistence, custom wallpapers per space, configurable hotkeys

### The Technical Approach That Works

All working solutions bypass native macOS Spaces entirely:

1. Use a single native Space (or minimal native Spaces)
2. Hide windows by moving them off-screen (x < -5000)
3. Show windows by restoring saved positions
4. Track virtual space membership in Lua tables
5. Window IDs are ephemeral - persistence uses app+title matching

**Why this works:**
- No reliance on broken private APIs
- Full control over window visibility
- Can implement any workspace metaphor
- Survives macOS updates

**Limitations:**
- Mission Control won't show virtual spaces
- Multi-monitor needs careful handling
- Window matching on restore isn't perfect
- Single native Space means no native gestures between spaces

### Custom Proof-of-Concept Implementation

We built a custom VirtualSpaces.lua module demonstrating the window-visibility approach:
- Hides windows by moving to x=-10000, stores original positions
- Tracks windowToSpace mapping, stickyWindows
- Window filter watches creation/destruction
- Visual overview: Mission Control-like grid with scaled window previews
- State persistence via app:title matching

This proved the concept works, but EnhancedSpaces.spoon has years of polish and edge case handling.

### If EnhancedSpaces Doesn't Work Out

If EnhancedSpaces.spoon proves unsuitable, alternatives to explore:

1. **Fork and fix** one of the broken solutions once/if Apple provides a new API
2. **Enhance the custom implementation** we prototyped
3. **AeroSpace** if app-level (not window-level) workspace assignment is acceptable
4. **Accept the limitation** and use aggressive app-to-space assignment with keyboard shortcuts

The key insight is that any solution depending on `hs.spaces.moveWindowToSpace` or Yabai's equivalent is broken on Sequoia. Only the window-visibility-hiding approach works.

---

## Spoon Management Tools

### Background on Hammerspoon Ecosystem

Hammerspoon is a macOS automation tool that uses Lua. Plugins are called "Spoons" and are conventionally stored in `~/.hammerspoon/Spoons/`. However, the ecosystem has no real package manager - just manual downloads or a bootstrap-required SpoonInstall spoon that:
- Requires manual installation itself (catch-22)
- Only works with repos following a specific structure
- Has no lockfiles, versioning, or dependency resolution
- Doesn't help with third-party spoons like EnhancedSpaces

We're building a simple spoon management system:
- Spoons are git clones stored in `~/.spoons/`
- Hammerspoon's `package.path` will be configured to load from there
- A lockfile (`spoonman`) captures exact repos and SHAs for reproducibility

## Directory Structure

```
~/.spoons/
├── EnhancedSpaces.spoon/     # git clone of a spoon repo
├── SomeOther.spoon/          # another spoon
└── spoonman                  # lockfile (generated by speeze)
```

## Commands to Implement

### `upspoon`

Update spoons by pulling latest from their remotes.

```bash
# Update all spoons
upspoon

# Update specific spoon(s)
upspoon EnhancedSpaces.spoon
upspoon EnhancedSpaces.spoon SomeOther.spoon
```

Behavior:
- If no arguments, iterate all `*.spoon` directories in `~/.spoons`
- For each spoon: `git -C <path> pull --ff-only`
- Use `--ff-only` to avoid surprise merges; fail loudly if not fast-forwardable
- Print status for each spoon (already up to date, updated to SHA, or error)
- Exit non-zero if any spoon fails to update

### `speeze`

Freeze current spoon state to the lockfile (like `pip freeze` or `npm shrinkwrap`).

```bash
# Update spoonman lockfile
speeze
```

Behavior:
- Iterate all `*.spoon` directories in `~/.spoons`
- For each, extract:
  - Remote URL: `git -C <path> remote get-url origin`
  - Current SHA: `git -C <path> rev-parse HEAD`
  - Current branch/ref: `git -C <path> symbolic-ref --short HEAD` (or "detached" if detached)
- Write to `~/.spoons/spoonman` in a parseable format

### `spoonman` lockfile format

Use a simple, human-readable format:

```
# spoonman - generated by speeze
# Run `upspoon` to update, `speeze` to regenerate this file

EnhancedSpaces.spoon
  repo: https://github.com/franzbu/EnhancedSpaces.spoon.git
  sha: a1b2c3d4e5f6...
  branch: main

SomeOther.spoon
  repo: https://github.com/someone/SomeOther.spoon.git
  sha: f6e5d4c3b2a1...
  branch: master
```

Alternatively, if you prefer something more machine-friendly, JSON is acceptable:

```json
{
  "generated": "2025-01-07T12:00:00Z",
  "spoons": {
    "EnhancedSpaces.spoon": {
      "repo": "https://github.com/franzbu/EnhancedSpaces.spoon.git",
      "sha": "a1b2c3d4e5f6...",
      "branch": "main"
    }
  }
}
```

Pick whichever you think is cleaner. I slightly prefer the text format for easy `grep`/`awk` but won't complain about JSON.

## Future Commands (do not implement yet, but design with these in mind)

- `inspoon <repo-url>` - clone a spoon into `~/.spoons`
- `unspoon <name>` - remove a spoon
- `respoon` - restore spoons from `spoonman` lockfile (clone missing, checkout exact SHAs)

## Implementation Notes

- Write as shell scripts (bash or zsh, your choice - this is macOS so both are available)
- Scripts should go in a `bin/` directory in this repo
- Include a small `install.sh` that symlinks the scripts to `~/.local/bin` or similar
- Create `~/.spoons` if it doesn't exist
- Handle edge cases:
  - Spoon directory exists but isn't a git repo
  - Spoon has uncommitted changes (warn but continue for `speeze`, refuse to pull for `upspoon`)
  - Remote URL uses SSH vs HTTPS (just capture whatever is configured)
  - No spoons installed yet

## Hammerspoon Integration

After implementing the scripts, provide a snippet for `~/.hammerspoon/init.lua` that:
1. Adds `~/.spoons` to Hammerspoon's spoon search path
2. Example of loading a spoon from there

Something like:
```lua
-- Load spoons from ~/.spoons
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.spoons/?.spoon/init.lua"
```

### EnhancedSpaces.spoon Configuration

Once spoon management is working, here's the minimal EnhancedSpaces setup for 6 spaces:

```lua
local EnhancedSpaces = hs.loadSpoon('EnhancedSpaces')
EnhancedSpaces:new({
  mSpaces = { '1', '2', '3', '4', '5', '6' },
  startmSpace = '1',
})
```

**Default keybindings in EnhancedSpaces:**
- `Ctrl+S/A`: cycle through spaces
- `Ctrl+Q/W`: move window left/right and follow
- `Ctrl+D/F`: move window left/right (stay on current space)
- `Ctrl+Shift+N`: create window reference (sticky) on space N
- `Alt+N`: switch to space N
- `Alt+Ctrl+N`: move window to space N
- `Alt+Tab`: mSpace Control (grid overview with window previews)

## Testing

Create a simple test flow I can run:
1. Clone EnhancedSpaces.spoon manually to verify the directory structure
2. Run `speeze` to generate lockfile
3. Run `upspoon` to verify update logic
4. Verify lockfile format is correct

---

## User Context

### Dotfiles Setup

The user's dotfiles are at github.com/indexzero/dotfiles with:
- `scripts/` directory for helper scripts
- `templates/` directory
- `install.sh` for setup
- Migrated to zsh (uses zimfw and/or starship based on issue #17)
- No Hammerspoon configuration yet

Hammerspoon will be installed via Homebrew (`brew install --cask hammerspoon`).

### Integration Approach

Rather than putting spoons in the dotfiles repo (as git submodules), we're keeping them in `~/.spoons` as independent git clones. The `spoonman` lockfile can optionally be committed to dotfiles for reproducibility.

The Hammerspoon config itself (`~/.hammerspoon/init.lua`) can live in dotfiles and be symlinked, with spoon loading configured to use `~/.spoons`.

### User Background

The user is an experienced Node.js developer (creator of the `errs` library, working with JS since 2009), currently a security researcher at Chainguard working on supply chain security tooling. They prefer practical, working solutions over theoretical approaches and have a direct communication style. The "no package manager" situation in Hammerspoon probably feels like 2005 to them.

---

## Deliverables

1. `bin/upspoon` - update script
2. `bin/speeze` - freeze script  
3. `install.sh` - installation helper
4. `README.md` - usage documentation
5. Example `init.lua` snippet for Hammerspoon integration
