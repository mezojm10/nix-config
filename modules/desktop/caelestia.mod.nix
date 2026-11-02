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
    config,
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
      };

      # Link the repo copy instead of letting the module generate a read-only
      # store file, so shell.json can be edited in place. Caelestia watches the
      # file (settings.watchFiles) and reloads it on change.
      xdg.configFile."caelestia/shell.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/caelestia/shell.json";
    };
  };
}