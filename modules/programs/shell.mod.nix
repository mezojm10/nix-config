{...}: {
  flake.homeModules.shell = {pkgs, ...}: {
    # Shell aliases
    home.shellAliases = {
      cat = "bat";
      lg = "lazygit";
      vim = "nvim";
    };

    programs.carapace = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.bat = {
      enable = true;
      config = {theme = "tokyonight";};
      themes = {
        tokyonight = {
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "tokyonight.nvim";
            rev = "b262293ef481b0d1f7a14c708ea7ca649672e200";
            sha256 = "sha256-pMzk1gRQFA76BCnIEGBRjJ0bQ4YOf3qecaU6Fl/nqLE=";
          };
          file = "extras/sublime/tokyonight_night.tmTheme";
        };
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.git = {
      enable = true;
    };

    programs.lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            colorArg = "always";
            pager = "delta --color-only --dark --paging=never";
            useConfig = false;
          };
        };
      };
    };

    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.nushell = {
      enable = true;

      # Pick up `home.sessionVariables` (e.g. CLAUDE_CODE_CERT_STORE) in env.nu.
      loadSessionVariables = true;
    };

    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
      };
    };

    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      autosuggestion.enable = true;
      enable = true;
      enableCompletion = true;

      oh-my-zsh = {
        enable = true;
        plugins = ["git"];
        theme = "robbyrussell";
      };

      syntaxHighlighting.enable = true;
    };
  };
}
