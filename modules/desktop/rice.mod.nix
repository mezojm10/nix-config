{lib, ...}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in {
  flake.homeModules.rice = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Noctalia's GTK templates write ~/.config/gtk-{3,4}.0/noctalia.css and
      # import it from gtk.css on top of adw-gtk3, so GTK apps follow the
      # shell. Leave gtk.css unmanaged here so the apply hook can rewrite it.
      gtk = {
        enable = true;

        font = {
          name = "Inter";
          size = 11;
        };

        colorScheme = "dark";

        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };

        cursorTheme = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 24;
        };
      };

      home.pointerCursor = {
        enable = true;
        gtk.enable = true;
        x11.enable = true;
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      home.sessionVariables = {
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        TERMINAL = getExe pkgs.ghostty;
        XCURSOR_SIZE = "24";
        XCURSOR_THEME = "Bibata-Modern-Ice";
      };

      home.packages = with pkgs; [
        brightnessctl
        libnotify
        playerctl
      ];

      # niri's screenshot UI writes here and does not create the directory.
      home.activation.createScreenshotsDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run mkdir -p "$HOME/Pictures/Screenshots"
      '';

      # qtengine reads the KColorScheme and widget style that Noctalia writes
      # on every scheme change, so Qt apps follow the shell. No `style.name`,
      # because the QT_STYLE_OVERRIDE it sets also becomes the Qt Quick
      # Controls style and crashes Kirigami apps such as System Settings.
      qt = {
        enable = true;

        platformTheme = {
          name = "qtengine";
          package = [pkgs.qtengine pkgs.darkly];
        };

        # KDE apps read fonts and icons from kdeglobals; qtengine supplies their
        # palette from the KColorScheme Noctalia writes.
        kde.settings.kdeglobals = {
          General.ColorScheme = "noctalia";
          General.font = "Inter,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
          Icons.Theme = "Papirus-Dark";
        };
      };

      # Link the repo copies instead of copying them into the store, so edits
      # apply without a rebuild.
      home.file.".config/niri".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/niri";

      programs.ghostty = {
        enable = true;

        settings = {
          theme = "noctalia";
          font-family = "JetBrainsMono Nerd Font";
          font-size = 11;
          background-opacity = 0.94;
          window-padding-x = 12;
          window-padding-y = 12;
          window-decoration = false;
          cursor-style = "bar";
          cursor-style-blink = false;
          mouse-hide-while-typing = true;
          copy-on-select = "clipboard";
          confirm-close-surface = false;
          shell-integration = "detect";

          keybind = [
            "ctrl+shift+c=copy_to_clipboard"
            "ctrl+shift+v=paste_from_clipboard"
            "ctrl+shift+t=new_tab"
            "ctrl+shift+w=close_surface"
            "ctrl+shift+enter=new_split:right"
            "ctrl+shift+o=new_split:down"
          ];
        };

        themes.tokyonight = {
          background = "1a1b26";
          foreground = "c0caf5";
          cursor-color = "c0caf5";
          cursor-text = "1a1b26";
          selection-background = "292e42";
          selection-foreground = "c0caf5";

          palette = [
            "0=#15161e"
            "1=#f7768e"
            "2=#9ece6a"
            "3=#e0af68"
            "4=#7aa2f7"
            "5=#bb9af7"
            "6=#7dcfff"
            "7=#a9b1d6"
            "8=#414868"
            "9=#f7768e"
            "10=#9ece6a"
            "11=#e0af68"
            "12=#7aa2f7"
            "13=#bb9af7"
            "14=#7dcfff"
            "15=#c0caf5"
          ];
        };
      };
    };
  };
}
