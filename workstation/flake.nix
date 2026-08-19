{
  # The simple system that works (Gall's Law seed).
  #
  # Standalone home-manager only: no nix-darwin, no hosts, no profiles, no
  # sudo. It manages exactly the slice of $HOME declared in home.nix and
  # nothing else; install/setup.sh keeps owning every unported category.
  # When this has grown enough working parts, it forward-ports to
  # robbinshinds.family/workstation (home.nix is content-identical to
  # users/cjr/home.nix there, minus the profile import).
  description = "Charlie's home configuration — dotfiles nix seed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # try-me-maybe: Rust port of tobi/try (ships a home-manager module).
    # Requires indexzero/try.rs#5 (nix flake) merged to main.
    try = {
      url = "github:indexzero/try.rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, try, ... }: {
    homeConfigurations."cjr" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        try.homeModules.default
        ./home.nix
      ];
    };
  };
}
