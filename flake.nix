{
  description = "Mazin's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      specialArgs = inputs;
      modules = [
        ({ config, ... }: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })

        ./configuration.nix
        nix-homebrew.darwinModules.nix-homebrew

        {
          nix-homebrew = {
            # Install homebrew under the default prefix
            enable = true;

            # Apple Silicon Only
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "mazinabdallah";

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;

            taps = with inputs; {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-cask-fonts" = homebrew-cask-fonts;
              "homebrew/homebrew-services" = homebrew-services;
              "d12frosted/homebrew-emacs-plus" = homebrew-emacs-plus;
              "nikitabobko/homebrew-tap" = homebrew-nikitabobko;
            };

            # Disable manual tap additions
            mutableTaps = false;
          };
        }
      ];
    };
  };
}
