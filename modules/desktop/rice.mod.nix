{lib, ...}: let
  inherit (lib.lists) singleton;
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
      # Tokyo Night GTK theme. The `storm` tweak is the closest match to the
      # night palette used by niri, the bar, and Ghostty.
      gtk = {
        enable = true;

        font = {
          name = "Inter";
          size = 11;
        };

        theme = {
          name = "Tokyonight-Dark-Storm";
          package = pkgs.tokyonight-gtk-theme.override {
            colorVariants = ["dark"];
            themeVariants = ["default"];
            tweakVariants = ["storm"];
          };
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

        # The Breeze widget style and the Breeze Dark color scheme.
        kdePackages.breeze

        libnotify
        playerctl
        polkit_gnome
        wlogout
      ];

      # niri's screenshot UI writes here and does not create the directory.
      home.activation.createScreenshotsDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run mkdir -p "$HOME/Pictures/Screenshots"
      '';

      # KDE's platform theme: the Breeze style with Breeze Dark colors, read
      # from color-schemes/BreezeDark.colors since kdeglobals carries no color
      # groups of its own. No `style.name`, because the QT_STYLE_OVERRIDE it
      # sets also becomes the Qt Quick Controls style and crashes Kirigami
      # apps such as System Settings.
      qt = {
        enable = true;
        platformTheme.name = "kde";

        kde.settings.kdeglobals = {
          General.ColorScheme = "BreezeDark";
          General.font = "Inter,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
          Icons.Theme = "Papirus-Dark";
        };
      };

      # Link the repo copies instead of copying them into the store, so edits
      # apply without a rebuild.
      home.file = {
        ".config/niri".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/niri";
        ".config/quickshell/tokyo-night".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/quickshell";
        ".config/wlogout".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/wlogout";
      };

      # Lets xdg-desktop-portal associate Quickshell's layer surfaces with an app.
      xdg.desktopEntries."org.quickshell" = {
        name = "Quickshell";
        exec = "quickshell";
        type = "Application";
        noDisplay = true;
      };

      programs.ghostty = {
        enable = true;

        settings = {
          theme = "tokyonight";
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

      programs.fuzzel = {
        enable = true;

        settings = {
          main = {
            font = "JetBrainsMono Nerd Font:size=11";
            terminal = getExe pkgs.ghostty;
            layer = "overlay";
            namespace = "launcher";
            width = 44;
            lines = 12;
            horizontal-pad = 20;
            vertical-pad = 20;
            inner-pad = 8;
            prompt = "❯";
            icon-theme = "Papirus-Dark";
            icons-enabled = "yes";
          };

          colors = {
            background = "1a1b26f2";
            text = "c0caf5ff";
            prompt = "7aa2f7ff";
            placeholder = "565f89ff";
            input = "c0caf5ff";
            match = "bb9af7ff";
            selection = "292e42ff";
            selection-text = "c0caf5ff";
            selection-match = "7dcfffff";
            counter = "565f89ff";
            border = "7aa2f7ff";
          };

          border = {
            width = 2;
            radius = 12;
          };
        };
      };

      programs.swaylock = {
        enable = true;

        settings = {
          color = "1a1b26";
          inside-color = "1a1b26";
          inside-clear-color = "1a1b26";
          inside-ver-color = "1a1b26";
          inside-wrong-color = "1a1b26";
          ring-color = "7aa2f7";
          ring-clear-color = "7dcfff";
          ring-ver-color = "9ece6a";
          ring-wrong-color = "f7768e";
          key-hl-color = "9ece6a";
          bs-hl-color = "f7768e";
          separator-color = "00000000";
          text-color = "c0caf5";
          text-clear-color = "c0caf5";
          text-ver-color = "c0caf5";
          text-wrong-color = "f7768e";
          line-color = "292e42";
          line-uses-inside = true;
          font = "JetBrainsMono Nerd Font";
          font-size = 20;
          indicator-radius = 120;
          indicator-thickness = 6;
          show-failed-attempts = true;
          fade-in = 0.2;
        };
      };

      services.mako = {
        enable = true;

        settings = {
          background-color = "#1a1b26";
          text-color = "#c0caf5";
          border-color = "#7aa2f7";
          progress-color = "over #292e42";
          border-radius = 12;
          border-size = 2;
          default-timeout = 6000;
          anchor = "top-right";
          margin = 12;
          padding = 12;
          width = 360;
          height = 180;
          font = "JetBrainsMono Nerd Font 10";
          icons = true;
          max-icon-size = 48;
          layer = "overlay";

          "urgency=critical" = {
            border-color = "#f7768e";
            default-timeout = 0;
          };
        };
      };

      services.cliphist = {
        enable = true;
      };

      services.swayidle = {
        enable = true;

        events = {
          before-sleep = "${getExe pkgs.swaylock} --daemonize";
          lock = "${getExe pkgs.swaylock} --daemonize";
        };

        # Locking only. Idle suspend is set in System Settings > Power
        # Management (powerdevil).
        timeouts = singleton {
          timeout = 300;
          command = "${getExe pkgs.swaylock} --daemonize";
        };
      };

      programs.quickshell = {
        enable = true;
        activeConfig = "tokyo-night";
        systemd.enable = true;
      };

      # mako has no upstream unit, so start it with the graphical session.
      systemd.user.services.mako = {
        Unit = {
          Description = "mako notification daemon";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
          Requisite = ["graphical-session.target"];
        };

        Service = {
          ExecStart = getExe pkgs.mako;
          Restart = "on-failure";
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
