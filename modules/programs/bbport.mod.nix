{
  inputs,
  lib,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr path;
in {
  flake.homeModules.bbport = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) mapAttrsToList optionalAttrs;
    inherit (lib.hm.dag) entryAfter;
    inherit (lib.strings) concatStringsSep escapeShellArg;

    bbport = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.bbport;

    # Only the folders that are set, as settings.json keys the launcher reads.
    seed =
      optionalAttrs (config.programs.bbport.gameDir != null) {
        game_dir = toString config.programs.bbport.gameDir;
      }
      // optionalAttrs (config.programs.bbport.userDir != null) {
        user_dir = toString config.programs.bbport.userDir;
      };
  in {
    options.programs.bbport = {
      enable = mkEnableOption "the native Bloodborne PC port";

      gameDir = mkOption {
        type = nullOr path;
        default = null;
        example = "/mnt/games/Games/Bloodborne/game";
        description = ''
          Folder holding the extracted game, with eboot.bin directly inside.
        '';
      };

      userDir = mkOption {
        type = nullOr path;
        default = null;
        example = "/mnt/games/Games/Bloodborne/Saves";
        description = ''
          Saves folder of the port (savedata, trophy, shader). It is the same
          layout on Windows, so an existing folder can be reused.
        '';
      };
    };

    config = mkIf (config.programs.bbport.enable && pkgs.stdenv.hostPlatform.isLinux) {
      home.packages = [bbport];

      xdg.desktopEntries.bloodborne = {
        name = "Bloodborne";
        genericName = "Action role-playing game";
        comment = "Native Bloodborne PC port";
        exec =
          if config.programs.bbport.gameDir == null
          then getExe bbport
          else "${getExe bbport} --play";
        icon = "applications-games";
        categories = ["Game"];
        settings.PrefersNonDefaultGPU = "true";
      };

      # The launcher owns settings.json; these folders are only filled in while
      # they are empty, so a folder picked in the launcher always wins.
      home.activation.bbportSettings = mkIf (seed != {}) (entryAfter ["writeBoundary"] ''
        settings="$HOME/.config/bbport-launcher/settings.json"

        run mkdir --parents "$HOME/.config/bbport-launcher"
        run touch "$settings"

        tmp="$(mktemp)"
        ${concatStringsSep "\n" (mapAttrsToList (key: value: ''
            ${getExe pkgs.jq} --slurp --arg key ${key} --arg value ${escapeShellArg value} \
              '.[0] // {} | if (.[$key] // "") == "" then .[$key] = $value else . end' "$settings" > "$tmp"
            run mv "$tmp" "$settings"
          '')
          seed)}
      '');
    };
  };
}
