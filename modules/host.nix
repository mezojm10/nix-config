{
  config,
  inputs,
  ...
}: let
  user = "mazinabdallah";
  # Compose a nix-darwin configuration from all collected darwin/hm features.
  # The home-manager integration is nested inside darwin, so its own features
  # are passed via home-manager.users.${user}.
in {
  flake.darwinConfigurations = {
    "Mazins-MacBook-Air" = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";

      modules =
        [
          {
            users.users.${user}.home = "/Users/${user}";
            system.primaryUser = user;
          }

          inputs.home-manager.darwinModules.home-manager
          {
            # useGlobalPkgs is off so home-manager evaluates its own nixpkgs,
            # letting home-features set nixpkgs.config (e.g. allowUnfreePredicate).
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.${user} = {
              imports = builtins.attrValues config.flake.modules.homeManager;
              home = {
                username = user;
                homeDirectory = "/Users/${user}";
              };
            };
          }
        ]
        ++ builtins.attrValues config.flake.modules.darwin;
    };
  };
}
