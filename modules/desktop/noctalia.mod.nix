{lib, ...}: let
  inherit (lib.modules) mkIf;
in {
  flake.nixosModules.noctalia = {...}: {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };
  };

  flake.homeModules.noctalia = {
    config,
    pkgs,
    ...
  }: {
    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.noctalia = {
        enable = true;

        settings = {
          backdrop.enabled = true;

          bluetooth.connection_notifications = true;

          brightness.enable_ddcutil = true;

          shell = {
            font_family = "Inter";
            greeter_sync.auto_sync = true;
            launch_apps_as_systemd_services = true;
            polkit_agent = true;
            screen_corners.enabled = true;
            settings_window_translucent = true;

            launcher = {
              categories = false;
              category_icons_only = true;
              layout = "simple";
            };

	    # Hibernate after suspend
	    session.power.suspend = "systemctl suspend-then-hibernate";
          };

          theme = {
            mode = "dark";
            source = "wallpaper";
            wallpaper_scheme = "m3-tonal-spot";

            templates = {
              enable_builtin_templates = true;
              builtin_ids = ["gtk3" "gtk4" "ghostty" "helix" "kcolorscheme" "niri"];
            };
          };

          wallpaper.directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        };
      };
    };
  };
}
