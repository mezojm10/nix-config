{
  inputs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  perSystem = {system, ...}: {
    packages.caelestia-shell = inputs.caelestia-shell.packages.${system}.with-cli;
  };

  flake.homeModules.caelestia = {
    pkgs,
    ...
  }: {
    imports = [inputs.caelestia-shell.homeManagerModules.default];

    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.caelestia = {
        enable = true;
        cli.enable = true;

        systemd = {
          enable = true;
          target = "graphical-session.target";
        };

        settings = {
          bar.workspaces.shown = 9;
        };
      };
    };
  };
}