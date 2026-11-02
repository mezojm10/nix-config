{
  inputs,
  lib,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in {
  flake.nixosModules.gaming = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = ["steam" "steam-unwrapped"];
    nixpkgs.overlays = [inputs.millennium.overlays.default];

    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;
      package = pkgs.millennium-steam;

      # Games run with the system PATH, which does not include the user
      # profile where home-manager installs MangoHud. libnotify is here so the
      # Millennium notification backend can run notify-send inside Steam's
      # bubblewrap environment.
      extraPackages = [pkgs.libnotify pkgs.mangohud];
    };
  };

  flake.homeModules.gaming = {
    lib,
    osConfig,
    pkgs,
    ...
  }: {
    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [pkgs.bottles];

      # Millennium plugin that drains Steam's own toast queue and forwards it
      # through notify-send, so Caelestia's NotificationServer handles it.
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
