# workstation — the nix seed

Standalone [home-manager](https://github.com/nix-community/home-manager)
managing a growing slice of `$HOME`. Deliberately the *simple system that
works* (Gall's Law): no nix-darwin, no hosts, no profiles, no sudo — those
live in robbinshinds.family/workstation and this seed forward-ports there
when it has earned it. `install/setup.sh` keeps owning every category not
yet listed in `home.nix`.

## Bootstrap (once)

```sh
# 1. Install nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. First switch (also generates flake.lock — commit it!)
cd ~/Git/indexzero/dotfiles/workstation
nix run github:nix-community/home-manager -- switch --flake .#cjr
git add flake.lock && git commit -m "chore(workstation): pin flake inputs"
```

## Every time after

```sh
install/nix        # or: home-manager switch --flake ~/Git/indexzero/dotfiles/workstation#cjr
```

## Migration ledger

| Category | Owner |
|---|---|
| CLI tools (`brew.d/Brewfile.cli`) | **home.nix** (exa→eza; ccat/nono/googleworkspace-cli/fonts stay brew) |
| try (`tryme` + shell function) | **home.nix** (`programs.try`, via the try.rs flake) |
| starship / atuin binaries | **home.nix** (configs still `settings/` — next slice) |
| everything else | `install/setup.sh`, as always |

Rollback: `home-manager generations` lists them; activate any previous one
directly. Your `.backup/` dir remains untouched by all of this.
