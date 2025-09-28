# Brewfiles

Organized Homebrew packages by concern for selective installation.

## Structure

- `Brewfile` - Main file that includes all others
- `Brewfile.dev` - Development tools (gcc, cmake, pyenv, etc.)
- `Brewfile.vcs` - Version control (gh, git-lfs, graphite)
- `Brewfile.cli` - CLI utilities (bat, exa, fzf, etc.)
- `Brewfile.docs` - Documentation & visualization (LaTeX, diagrams)
- `Brewfile.databases` - Database systems (mysql, postgresql, mongodb)
- `Brewfile.media` - Media processing (imagemagick, ffmpeg)
- `Brewfile.system` - System utilities (fastfetch, eul, pearcleaner)
- `Brewfile.network` - Network & security tools (mitmproxy)
- `Brewfile.productivity` - Productivity apps (espanso, nb, cointop)
- `Brewfile.terminals` - Terminal emulators (warp, ghostty)

## Usage

### Install everything
```bash
cd install/brew.d
brew bundle
```

### Install specific category
```bash
brew bundle --file=install/brew.d/Brewfile.dev
brew bundle --file=install/brew.d/Brewfile.cli
```

### Check what would be installed
```bash
brew bundle check --file=install/brew.d/Brewfile.dev
```

### List installed packages
```bash
brew bundle list --file=install/brew.d/Brewfile
```

## Notes

- The main `Brewfile` uses `instance_eval` to include all sub-Brewfiles
- Comment out categories in the main Brewfile to exclude them
- Each Brewfile is self-contained and can be used independently
- Taps are included in the relevant Brewfile for their packages