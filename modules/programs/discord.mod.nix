{lib, ...}: let
  inherit (lib.modules) mkIf;
in {
  # The license check asks for this list while `pkgs` is still being
  # instantiated, so it must live in a module that does not take `pkgs`. The
  # FHS wrapper and the client it wraps are checked separately.
  flake.homeModules.discord-unfree = {
    nixpkgs.allowedUnfreePackages = ["discord" "discord-unwrapped"];
  };

  flake.homeModules.discord = {pkgs, ...}: {
    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      # The home-manager module links settings.json with SKIP_HOST_UPDATE set, so
      # the wrapped client (disableUpdates) does not try to update itself.
      programs.discord = {
        enable = true;
      };
    };
  };
}
