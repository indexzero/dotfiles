#!/usr/bin/env zsh

# Hammerspoon installation and setup script
#
# Installs Hammerspoon, spoon management tools, and Faces (fast virtual workspaces)
#
# Usage: hammerspoon/install.sh [OPTIONS]
#
# Options:
#   --no-upgrade    Skip upgrade prompts for existing installations
#   --help, -h      Show this help message

set -e

SCRIPT_DIR="${0:A:h}"
SPOONS_DIR="${SPOONS_DIR:-$HOME/.spoons}"
HAMMERSPOON_DIR="$HOME/.hammerspoon"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

# -----------------------------------------------------------------------------
# CLI Argument Parsing
# -----------------------------------------------------------------------------

NO_UPGRADE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-upgrade)
      NO_UPGRADE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --no-upgrade    Skip upgrade prompts for existing installations"
      echo "  --help, -h      Show this help message"
      echo ""
      echo "This script will:"
      echo "  1. Install Hammerspoon via Homebrew"
      echo "  2. Create ~/.spoons directory"
      echo "  3. Symlink upspoon and speeze to ~/.local/bin"
      echo "  4. Install Faces (fast virtual workspaces)"
      echo "  5. Create init.lua configuration"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

prompt_upgrade() {
  local tool="$1"
  local current_version="$2"

  if [[ "$NO_UPGRADE" == "true" ]]; then
    echo "  Skipping upgrade (--no-upgrade specified)"
    return 1
  fi

  echo -n "  Upgrade $tool? (current: $current_version) [y/N]: "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

prompt_overwrite() {
  local file="$1"

  echo -n "  $file exists. Overwrite? [y/N]: "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# Hammerspoon Installation
# -----------------------------------------------------------------------------

echo "Setting up Hammerspoon..."
echo ""

if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew is required"
  echo "Run install/brew first"
  exit 1
fi

echo "[Hammerspoon]"
if brew list --cask hammerspoon &>/dev/null; then
  echo "  Already installed"
  if prompt_upgrade "Hammerspoon" "installed"; then
    brew upgrade --cask hammerspoon || true
  fi
else
  echo "  Installing via Homebrew..."
  brew install --cask hammerspoon
fi
echo ""

# -----------------------------------------------------------------------------
# Directory Setup
# -----------------------------------------------------------------------------

echo "[Directories]"

if [[ ! -d "$SPOONS_DIR" ]]; then
  echo "  Creating $SPOONS_DIR"
  mkdir -p "$SPOONS_DIR"
else
  echo "  $SPOONS_DIR exists"
fi

if [[ ! -d "$HAMMERSPOON_DIR" ]]; then
  echo "  Creating $HAMMERSPOON_DIR"
  mkdir -p "$HAMMERSPOON_DIR"
else
  echo "  $HAMMERSPOON_DIR exists"
fi

if [[ ! -d "$BIN_DIR" ]]; then
  echo "  Creating $BIN_DIR"
  mkdir -p "$BIN_DIR"
else
  echo "  $BIN_DIR exists"
fi

echo ""

# -----------------------------------------------------------------------------
# Symlink Scripts
# -----------------------------------------------------------------------------

echo "[Spoon Management Tools]"

for script in upspoon speeze; do
  src="$SCRIPT_DIR/bin/$script"
  dst="$BIN_DIR/$script"

  if [[ -L "$dst" ]]; then
    current_target=$(readlink "$dst")
    if [[ "$current_target" == "$src" ]]; then
      echo "  $script: already linked"
    else
      echo "  $script: linked to $current_target (updating)"
      ln -sf "$src" "$dst"
    fi
  elif [[ -e "$dst" ]]; then
    echo "  $script: file exists at $dst (not a symlink, skipping)"
  else
    echo "  $script: linking"
    chmod +x "$src"
    ln -s "$src" "$dst"
  fi
done

echo ""

# -----------------------------------------------------------------------------
# Install Faces
# -----------------------------------------------------------------------------

echo "[Faces]"

FACES_SRC="$SCRIPT_DIR/faces/init.lua"
FACES_DST="$HAMMERSPOON_DIR/faces.lua"

if [[ -L "$FACES_DST" ]]; then
  current_target=$(readlink "$FACES_DST")
  if [[ "$current_target" == "$FACES_SRC" ]]; then
    echo "  Already linked"
  else
    echo "  Linked to $current_target (updating)"
    ln -sf "$FACES_SRC" "$FACES_DST"
  fi
elif [[ -e "$FACES_DST" ]]; then
  echo "  File exists at $FACES_DST (not a symlink)"
  if prompt_overwrite "$FACES_DST"; then
    rm "$FACES_DST"
    ln -s "$FACES_SRC" "$FACES_DST"
    echo "  Replaced with symlink"
  fi
else
  echo "  Linking faces.lua"
  ln -s "$FACES_SRC" "$FACES_DST"
fi

echo ""

# -----------------------------------------------------------------------------
# Hammerspoon Configuration
# -----------------------------------------------------------------------------

echo "[Hammerspoon Config]"

INIT_LUA="$HAMMERSPOON_DIR/init.lua"

INIT_CONTENT='-- Hammerspoon configuration
-- Faces: Fast virtual workspaces

local Faces = dofile(hs.configdir .. "/faces.lua")

Faces.setup({
  faces = { "1", "2", "3", "4", "5", "6" },
  startFace = "1",
})

-- Keybindings
Faces.bindSwitchFace({ "ctrl", "shift" })                -- Ctrl+Shift+1-6: switch to face
Faces.bindMoveFace({ "ctrl", "alt", "shift" })           -- Ctrl+Option+Shift+1-6: move window to face
Faces.bindCycleNext({ "ctrl" }, "space")                 -- Ctrl+Space: cycle next
Faces.bindCyclePrev({ "ctrl", "shift" }, "space")        -- Ctrl+Shift+Space: cycle prev
Faces.bindEscapeHatch({ "ctrl", "alt", "shift" }, "h")   -- Ctrl+Alt+Shift+H: restore all windows

-- Keybindings summary:
-- Ctrl+Space              Cycle to next face
-- Ctrl+Shift+Space        Cycle to previous face
-- Ctrl+Shift+1-6          Switch to face 1-6
-- Ctrl+Option+Shift+1-6   Move window to face 1-6
-- Ctrl+Option+Shift+H     ESCAPE HATCH: restore all windows
'

if [[ -f "$INIT_LUA" ]]; then
  echo "  $INIT_LUA exists"
  if prompt_overwrite "$INIT_LUA"; then
    echo "$INIT_CONTENT" > "$INIT_LUA"
    echo "  Overwritten"
  else
    echo "  Skipped (backup your config and re-run if needed)"
  fi
else
  echo "  Creating $INIT_LUA"
  echo "$INIT_CONTENT" > "$INIT_LUA"
fi

echo ""

# -----------------------------------------------------------------------------
# Generate Initial Lockfile
# -----------------------------------------------------------------------------

echo "[Lockfile]"

if command -v speeze &>/dev/null || [[ -x "$BIN_DIR/speeze" ]]; then
  echo "  Running speeze to generate lockfile..."
  "$BIN_DIR/speeze"
else
  echo "  speeze not in PATH, skipping lockfile generation"
  echo "  Run 'speeze' manually after adding $BIN_DIR to PATH"
fi

echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo "============================================"
echo "Hammerspoon setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open Hammerspoon and grant accessibility permissions"
echo "  2. Reload config: Hammerspoon menu -> Reload Config"
echo ""
echo "Faces keybindings:"
echo "  Ctrl+Space              Cycle to next face"
echo "  Ctrl+Shift+Space        Cycle to previous face"
echo "  Ctrl+Shift+1-6          Switch to face 1-6"
echo "  Ctrl+Option+Shift+1-6   Move window to face 1-6"
echo ""
echo "Spoon management:"
echo "  upspoon          Update all spoons"
echo "  speeze           Freeze state to lockfile"
