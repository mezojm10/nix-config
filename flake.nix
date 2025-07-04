{
  description = "Mazin's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-cask-fonts = {
      url = "github:homebrew/homebrew-cask-fonts";
      flake = false;
    };

    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };

    homebrew-emacs-plus = {
      url = "github:d12frosted/homebrew-emacs-plus";
      flake = false;
    };

    homebrew-nikitabobko = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    darwin,
    nixpkgs,
    nix-homebrew,
    home-manager,
    ...
  }: let
    darwin-system = import ./system/darwin.nix {inherit inputs username;};
    username = "mazinabdallah";
  in {
    darwinConfigurations = {
      Mazins-MacBook-Air = darwin-system "aarch64-darwin";
      x86_64 = darwin-system "x86_64-darwin";
    };

    formatter = {
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
    };

    devShells = {
      aarch64-darwin = {
        default = let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        in
          pkgs.mkShell {
            buildInputs = with pkgs; [
              nixd
            ];
          };
      };

      x86_64-darwin = {
        default = let
          pkgs = nixpkgs.legacyPackages.x86_64-darwin;
        in
          pkgs.mkShell {
            buildInputs = with pkgs; [
              nixd
            ];
          };
      };

      x86_64-linux = {
        default = let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
          pkgs.mkShell {
            buildInputs = with pkgs; [
              nixd
            ];
          };
      };
    };
  };
}
