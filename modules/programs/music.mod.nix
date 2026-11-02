{
  inputs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  flake.homeModules.music = {pkgs, ...}: {
    home.packages = mkIf pkgs.stdenv.hostPlatform.isLinux [
      inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
