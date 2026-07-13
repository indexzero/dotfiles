# Charlie — home configuration (dotfiles nix seed)
#
# First slice ported from install/: the Brewfile.cli formula list (as nix
# packages) plus try-me-maybe via its home-manager module. Tool configs
# (starship.toml, atuin, git) are the NEXT slice — until then
# install/setup.sh still owns them, and these programs pick up those
# configs from their usual locations.
#
# Forward-port note: keep this file content-identical to
# robbinshinds.family workstation/users/cjr/home.nix (minus its profile
# import) so promotion is a copy, not a rewrite.
{ config, pkgs, lib, ... }:

{
  home.username = "cjr";
  home.homeDirectory = "/Users/cjr";
  home.stateVersion = "24.05";

  programs.try.enable = true;
  # path defaults to ~/src/tries — set explicitly when you want elsewhere:
  # programs.try.path = "~/src/tries";

  # install/brew.d/Brewfile.cli, as nixpkgs packages.
  # Substitutions from the Brewfile, recorded honestly:
  #   exa  -> eza   (exa is unmaintained; eza is its continuation)
  #   ccat -> left in brew.d (not in nixpkgs)
  #   nono, googleworkspace-cli -> not in nixpkgs; stay brew/bespoke
  #   font-meslo-lg-nerd-font (cask) -> stays in brew.d
  home.packages = with pkgs; [
    tree
    bat
    eza
    fd
    fzf
    coreutils
    duf
    dust
    xsv
    jq
    yq-go
    jnv
    tmux
    gum
    glow
    ttyd
  ];

  # Enabled with their defaults; the starship.toml/atuin config port from
  # settings/ is the next slice (home-manager will then own the files and
  # install/starship + install/atuin retire).
  programs.starship.enable = true;
  programs.atuin.enable = true;
}
