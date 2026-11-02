{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    helium.url = "github:oxcl/nix-flake-helium-browser";
    helium.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.home-manager.follows = "home-manager";
    # Steam client plugin framework; the steam-notify plugin under
    # dotfiles/millennium forwards Steam's own toasts to the system daemon.
    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fork of github:caelestia-dots/shell ported to niri. The source lives in
    # ./caelestia-shell so shell changes apply without touching flake inputs.
    caelestia-shell = {
      url = "path:./caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.inputs.nixpkgs.follows = "nixpkgs";
      inputs.m3shapes.inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-cli.inputs.nixpkgs.follows = "nixpkgs";
    };
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
        listFilesRecursive ./.
        |> filter (hasSuffix ".mod.nix")
        |> (imports: imports ++ singleton inputs.flake-parts.flakeModules.modules);

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
