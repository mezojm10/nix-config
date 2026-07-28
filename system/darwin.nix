{
  inputs,
  username,
}: system: let
  system-config = import ../module/configuration.nix;
  home-manager-config = ../module/home-manager.nix;
in
  inputs.darwin.lib.darwinSystem {
    inherit system;
    # modules: allows for reusable code
    modules = [
      {
        users.users.${username}.home = "/Users/${username}";

        # Set system.primaryUser to the username
        system.primaryUser = username;
      }
      system-config

      inputs.home-manager.darwinModules.home-manager
      {
        # add home-manager settings here
        # useGlobalPkgs is off so home-manager evaluates its own nixpkgs,
        # which lets home-manager.nix set nixpkgs.config (e.g. allowUnfreePredicate).
        home-manager.useGlobalPkgs = false;
        home-manager.useUserPackages = true;
        # Move pre-existing files aside instead of aborting activation when
        # home-manager wants to take over a path that already has a real file.
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = {inherit inputs;};
        home-manager.users."${username}" = home-manager-config;
      }
      # add more nix modules here
    ];
  }
