# Faces

**Faces** = **Fa**st Spa**ces**

A minimal, high-performance virtual workspace manager for Hammerspoon.

## What It Does

Faces does exactly four things:

1. **Create a face** - Define a named virtual workspace
2. **Move window to face** - Send the focused window to a face
3. **Switch to face** - Show all windows on a face, hide the rest
4. **List faces** - See which face you're on and what's where

That's it. No window snapping, no grid layouts, no animations, no thumbnails.

## How It's Fast

### O(1) Window Lookups

Window-to-face mappings use a hash table keyed by window ID:

```lua
windowFaces[windowId] = faceName
```

No linear searches. Ever.

### Minimal Event Subscriptions

Only two window filter events:

- `windowCreated` - Add new windows to current face
- `windowDestroyed` - Clean up closed windows

No subscriptions to `windowMoved`, `windowFocused`, or `windowFullscreened`.

### Lazy Operations

- No upfront window enumeration
- No snapshot generation
- No canvas rendering

### Direct API Calls

Windows are hidden by moving off-screen and shown by restoring position:

```lua
-- Hide: move off-screen
window:setTopLeft({x = -10000, y = 0})

-- Show: restore saved position
window:setFrame(savedFrame)
```

No wrapper functions. No intermediate state.

## Installation

```lua
-- In ~/.hammerspoon/init.lua
local Faces = dofile("/path/to/faces/init.lua")

Faces.setup({
  faces = { "1", "2", "3", "4", "5", "6" },
  startFace = "1",
})

-- Keybindings
Faces.bindSwitchFace({ "alt" })           -- Alt+1-6: switch to face
Faces.bindMoveFace({ "cmd", "shift" })    -- Cmd+Shift+1-6: move window to face
```

## API

```lua
Faces.setup(config)           -- Initialize with face names
Faces.switchTo(faceName)      -- Switch to a face
Faces.moveWindow(faceName)    -- Move focused window to a face
Faces.currentFace()           -- Get current face name
Faces.list()                  -- Get all faces and their window counts
```

## License

MIT
