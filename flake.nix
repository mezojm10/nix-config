{
  nixConfig = {
    builders-use-substitutes = true;
    experimental-features = ["flakes" "nix-command" "pipe-operators"];
    flake-registry = "";
    substituters = ["https://nix-community.cachix.org"];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-users = ["@wheel"];
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    ({lib, ...}: let
      inherit (lib.filesystem) listFilesRecursive;
      inherit (lib.lists) filter singleton;
      inherit (lib.strings) hasSuffix;
    in {
      # Dendritic Pattern: auto-import every `*.mod.nix` top-level module.
      imports =
        filter (hasSuffix ".mod.nix") (listFilesRecursive ./.)
        ++ singleton inputs.flake-parts.flakeModules.modules;

      # Which systems perSystem is instantiated for (formatter, devShells).
      systems = ["aarch64-darwin" "x86_64-linux"];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devShells = {
          default = pkgs.mkShell {buildInputs = [pkgs.nixd];};
        };
      };
    });
}
