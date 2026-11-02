{lib, ...}: let
  inherit (lib.modules) mkIf;
in {
  flake.homeModules.music = {pkgs, ...}: {
    # fooyin plays a local library, scrobbles to Last.fm natively, and exposes
    # the standard MPRIS interface for the quickshell bar.
    home.packages = mkIf pkgs.stdenv.hostPlatform.isLinux [
      pkgs.fooyin
    ];
  };
}
