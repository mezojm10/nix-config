{lib, ...}: let
  inherit (lib.modules) mkIf;
in {
  flake.nixosModules.gaming = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = ["steam" "steam-unwrapped"];

    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;

      # Games run with the system PATH, which does not include the user
      # profile where home-manager installs MangoHud.
      extraPackages = [pkgs.mangohud];
    };
  };

  flake.homeModules.gaming = {
    osConfig,
    pkgs,
    ...
  }: {
    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [pkgs.bottles];

      programs.lutris = {
        enable = true;

        # Reuse the system Steam so Lutris and Steam share one prefix.
        steamPackage = osConfig.programs.steam.package;
      };

      programs.mangohud.enable = true;
    };
  };

  # Bottles pulls in lsfg-vk, whose license check asks for this list while
  # `pkgs` is still being instantiated. It must live in a module that does not
  # take `pkgs`, or the lookup recurses.
  flake.homeModules.gaming-unfree = {
    nixpkgs.allowedUnfreePackages = ["lsfg-vk"];
  };
}
