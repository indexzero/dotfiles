# workstation: the nix seed

Standalone [home-manager](https://github.com/nix-community/home-manager)
managing a growing slice of `$HOME`, applied through one local
[devenv Machine](https://devenv.sh/machines/) (`cjr`). Deliberately the
*simple system that works* (Gall's Law): no nix-darwin role, no remote
targets, no hosts, no profiles, no sudo. Those live in
robbinshinds.family/workstation, and this seed forward-ports there when it
has earned it. `install/setup.sh` keeps owning every category not yet listed
in `home.nix`.

## Bootstrap (once)

`install/nix` deploys from the installed clone (`~/.local/share/dotfiles`,
see `install/dotfiles`), never from a dev checkout. home-manager reads
`home.nix` from the clone, so a change reaches the machine the same way every
other dotfile does: merge to `main`, then `dotfiles pull`. Building is the
exception. It activates nothing, so it runs from the checkout.

```sh
# 1. Install nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. Build without activating, from the dev checkout (also generates devenv.lock)
cd ~/Git/indexzero/dotfiles/workstation
nix run github:NixOS/nixpkgs/nixpkgs-unstable#devenv -- build machines.cjr

# 3. Pin the inputs
git add devenv.lock && git commit -m "chore(workstation): pin devenv inputs"

# 4. Merge to main, then bring the clone up to date
dotfiles pull

# 5. Activate (bootstraps devenv with a one-shot `nix run` if needed)
install/nix
```

After the first deploy, `devenv` itself comes from the home profile.

To activate from a checkout before it merges, point the installer at it:
`DOTFILES_DIR=~/Git/indexzero/dotfiles install/nix`.

## Every time after

```sh
install/nix        # or, from the clone's workstation/: devenv machines deploy cjr
```

`install/nix --yes` skips deploy's confirmation prompt.

## Migration ledger

| Category | Owner |
|---|---|
| CLI tools (`brew.d/Brewfile.cli`) | **home.nix** (exa→eza; ccat/nono/googleworkspace-cli/fonts stay brew) |
| try (`tryme` + shell function) | **home.nix** (`programs.try`, via the try.rs flake) |
| starship / atuin binaries | **home.nix** (configs still `settings/`, next slice) |
| wrapper (`flake.nix`) | **devenv.nix** + **devenv.yaml** (one local Machine; devenv itself added inline) |
| everything else | `install/setup.sh`, as always |

## Rollback

`home-manager generations` lists them; activate any previous one directly.
Machines provides no rollback for the home-manager role (its `status` and
`rollback` commands cover NixOS only). Your `.backup/` dir remains untouched
by all of this.

## Why Machines, and the escape hatch

It's the same tool as the per-project environments, with one lockfile
(`devenv.lock`) instead of a separate flake. Forward-porting to the family
repo can become adding roles (nix-darwin, more machines) to a machine rather
than adopting a new architecture. Machines is experimental as of devenv 2.4,
but `home.nix` is an unchanged plain module, so leaving means swapping
`devenv.nix` + `devenv.yaml` back for a roughly 15-line `flake.nix`.
