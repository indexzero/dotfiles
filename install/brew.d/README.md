# Brewfiles

Organized Homebrew packages by concern for selective installation.

## Structure

Sets are cut by concern, and three of them by layer:

| Layer | Set | Needs |
|---|---|---|
| terminal | `Brewfile.terminal` | a display: emulators (warp, ghostty, cmux) and the font they render |
| shell | `Brewfile.shell` | a pty: starship, mise, tmux |
| cli | everything else | a shell |

Plus `Brewfile.desktop` for GUI applications with no relationship to the
shell. `terminal` and `desktop` are the headed sets. `profiles` maps a
profile name to the sets it omits: `headless` omits those two and
`databases`, which a VM has no use for either.

- `Brewfile` - Main file that includes all others
- `Brewfile.shell` - Prompt, runtime manager, multiplexer (starship, mise, tmux)
- `Brewfile.dev` - Development tools (gcc, cmake, ripgrep)
- `Brewfile.vcs` - Version control (gh, git-lfs, graphite)
- `Brewfile.cli` - CLI utilities (bat, exa, fzf, etc.)
- `Brewfile.docs` - Documentation & visualization (LaTeX, diagrams)
- `Brewfile.databases` - Database systems (mysql, postgresql)
- `Brewfile.media` - Media processing (imagemagick, ffmpeg)
- `Brewfile.system` - System utilities (fastfetch, tart, rclone)
- `Brewfile.network` - Network & security tools (mitmproxy)
- `Brewfile.devops` - Cloud & DevOps CLIs (fastly)
- `Brewfile.llms` - LLM tooling (icm, mq, deja-vu)
- `Brewfile.productivity` - Productivity CLIs (nb, cointop)
- `Brewfile.terminal` - Terminal emulators and font (warp, ghostty, cmux) — headed
- `Brewfile.desktop` - Desktop applications (codex, inkscape, betterdisplay) — headed

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