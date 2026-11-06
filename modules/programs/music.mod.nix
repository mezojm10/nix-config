{
  inputs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  flake.homeModules.music = {pkgs, ...}: {
    # fooyin plays a local library, scrobbles to Last.fm natively, and exposes
    # the standard MPRIS interface for the Noctalia bar. Sidra is the Apple
    # Music client, also exposed over MPRIS.
    home.packages = mkIf pkgs.stdenv.hostPlatform.isLinux [
      pkgs.fooyin
      inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
