# The simple system that works (Gall's Law seed): one local home-manager
# machine, applied with `devenv machines deploy cjr`.
#
# No nix-darwin role, no remote targets (no `target.host`), no hosts or
# profiles, no sudo. It manages exactly the slice of $HOME declared in
# home.nix and nothing else; install/setup.sh keeps owning every unported
# category. When this has grown enough working parts, it forward-ports to
# robbinshinds.family/workstation: home.nix stays content-identical to
# users/cjr/home.nix there (minus the profile import), so promotion is a
# copy.
#
# Machines is experimental as of devenv 2.4. home.nix is a plain
# home-manager module, so falling back to a standalone home-manager flake
# (homeConfigurations.cjr with the same two imports) is a roughly 15-line
# change.
{ inputs, ... }: {
  machines.cjr.home-manager.imports = [
    inputs.try.homeModules.default
    ./home.nix
    # devenv maintains itself after bootstrap. Kept out of home.nix so that
    # file stays content-identical to the family repo. nixpkgs-unstable has
    # carried devenv 2.4.0 (Machines) since 2026-09-24.
    ({ pkgs, ... }: { home.packages = [ pkgs.devenv ]; })
  ];
}
