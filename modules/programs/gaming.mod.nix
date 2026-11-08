{
  inputs,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in {
  flake.nixosModules.gaming = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = ["steam" "steam-unwrapped"];
    nixpkgs.overlays = [inputs.millennium.overlays.default];

    environment.systemPackages = let
      # Both panels are 1920x1080; change these two for another display.
      output = {
        width = 1920;
        height = 1080;
      };

      # 144 Hz divides evenly by 2 and 3, so 72/48 avoid 60-on-144 judder.
      presets = {
        native = {
          width = 1920;
          height = 1080;
          fps = 144;
          scaler = "fit";
          filter = "linear";
        };
        quality = {
          width = 1600;
          height = 900;
          fps = 144;
          scaler = "fit";
          filter = "fsr";
        };
        balanced = {
          width = 1280;
          height = 720;
          fps = 72;
          scaler = "fit";
          filter = "fsr";
        };
        performance = {
          width = 960;
          height = 540;
          fps = 48;
          scaler = "fit";
          filter = "fsr";
        };
        pixel = {
          width = 960;
          height = 540;
          fps = 144;
          scaler = "integer";
          filter = "nearest";
        };
      };

      mkPreset = name: preset: let
        script =
          /*
          bash
          */
          ''
            exec ${getExe pkgs.gamescope} \
              --output-width ${toString output.width} \
              --output-height ${toString output.height} \
              --nested-width ${toString preset.width} \
              --nested-height ${toString preset.height} \
              --nested-refresh ${toString preset.fps} \
              --scaler ${preset.scaler} \
              --filter ${preset.filter} \
              --fullscreen \
              -- "$@"
          '';
      in
        pkgs.writeShellScriptBin "gamescope-${name}" script;
    in
      singleton pkgs.gamescope ++ mapAttrsToList mkPreset presets;

    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;
      package = pkgs.millennium-steam;

      # Games run with the system PATH, which does not include the user
      # profile where home-manager installs MangoHud. libnotify is here so the
      # Millennium notification backend can run notify-send inside Steam's
      # bubblewrap environment.
      extraPackages = [pkgs.gamescope pkgs.libnotify pkgs.mangohud];
    };
  };

  flake.homeModules.gaming = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: {
    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [pkgs.bottles];

      # MangoHud re-reads this on every launch, so keep it a plain dotfile that
      # can be edited in place instead of a config generated at rebuild time.
      home.file.".config/MangoHud/MangoHud.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/mangohud/MangoHud.conf";

      # Millennium plugin that drains Steam's own toast queue and forwards it
      # through notify-send, so Noctalia's notification daemon handles it.
      home.file.".local/share/millennium/plugins/steam-notify.star".source = ../../dotfiles/millennium/steam-notify.star;

      # Millennium rewrites this file at runtime, so it has to stay a real file
      # in $HOME instead of a home-manager symlink. Merge the plugin in without
      # dropping any plugin the user enabled from the UI.
      home.activation.millenniumSteamNotify = lib.hm.dag.entryAfter ["writeBoundary"] ''
        config="$HOME/.config/millennium/config.json"

        run mkdir -p "$HOME/.config/millennium"
        run touch "$config"

        tmp="$(mktemp)"
        ${getExe pkgs.jq} -s '.[0] // {} | .plugins.enabledPlugins = (((.plugins.enabledPlugins // []) + ["steam-notify"]) | unique)' "$config" > "$tmp"
        run mv "$tmp" "$config"
      '';

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
