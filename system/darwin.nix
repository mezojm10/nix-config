{
  inputs,
  username,
}: system:
let
  system-config = import ../module/configuration.nix;
  home-manager-config = import ../module/home-manager.nix;
in
  inputs.darwin.lib.darwinSystem {
    inherit system;
    # modules: allows for reusable code
    modules = [
      {users.users.${username}.home = "/Users/${username}";}
      ({ config, ... }: {
        homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
      })
      system-config

      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.home-manager.darwinModules.home-manager
      {
        # add home-manager settings here
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users."${username}" = home-manager-config;

        # Homebrew
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
      # add more nix modules here
    ];
}
