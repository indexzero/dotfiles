# Next Steps: Starship Switch

Config is built and reviewed. Do these in order.

## 1. Brewfile — add starship + Nerd Font

```
brew "starship"
cask "font-meslo-lg-nerd-font"
```

Run `brew bundle` after adding.

## 2. Create starship-plain.toml (Terminal.app)

Copy `settings/starship/starship.toml` → `settings/starship/starship-plain.toml` and replace every Nerd Font glyph with ASCII fallbacks:

| Module | Nerd Font | Plain |
|---|---|---|
| `character` success/error | `❯` | `%` |
| `git_branch` symbol | ` ` | (empty string) |
| `jobs` symbol | ` ` | `* ` |
| `nodejs` symbol | ` ` | `node ` |
| `golang` symbol | ` ` | `go ` |
| `rust` symbol | ` ` | `rust ` |
| `bun` symbol | ` ` | `bun ` |
| `deno` symbol | ` ` | `deno ` |
| `docker_context` symbol | ` ` | `docker ` |
| `kubernetes` symbol | ` ` | `k8s ` |
| `gcloud` symbol | ` ` | `gcp ` |
| `terraform` symbol | `󱁢 ` | `tf ` |
| `python` symbol | ` ` | `py ` |
| `custom.worktree` format | `[ wt]` | `[wt]` |

## 3. Write install/starship

Symlink both configs into `~/Library/Application Support/starship/`:

```zsh
#!/usr/bin/env zsh
set -e
DOTFILES="$(cd "${0:A:h}/.." && pwd)"
SRC="$DOTFILES/settings/starship"
DST="$HOME/Library/Application Support/starship"
BACK="$HOME/.backup/starship"

if [ -L "$DST" ]; then
  [ "$(readlink "$DST")" = "$SRC" ] && { echo "Linked (already)"; exit 0; }
  rm "$DST"
elif [ -e "$DST" ]; then
  mkdir -p "$(dirname "$BACK")" && mv "$DST" "$BACK"
fi

mkdir -p "$HOME/Library/Application Support"
ln -s "$SRC" "$DST"
```

## 4. Update Ghostty font

In `settings/ghostty/config`, change:
```
font-family = "Menlo"
```
to:
```
font-family = "MesloLGM Nerd Font"
```

## 5. Update .zimrc — remove asciiship + deps

Remove these three lines from `dotfiles/.zimrc`:
```
zmodule duration-info
zmodule git-info
zmodule asciiship
```

## 6. Update .zshrc — wire in starship

Add at the bottom of `dotfiles/.zshrc`:

```zsh
# Starship — use plain config in Terminal.app (no Nerd Font)
[[ "$TERM_PROGRAM" == "Apple_Terminal" ]] && \
  export STARSHIP_CONFIG="$HOME/Library/Application Support/starship/starship-plain.toml"

eval "$(starship init zsh)"
```

## 7. Run

```sh
brew bundle
./install/starship
zimfw uninstall   # removes asciiship/duration-info/git-info modules
exec zsh
```

Restart Ghostty to pick up the font change.
