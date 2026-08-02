{...}: {
  flake.homeModules.shell = {pkgs, ...}: {
    # Shell aliases
    home.shellAliases = {
      cat = "bat";
      lg = "lazygit";
      vim = "nvim";
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
      # Completions for jj
      extraConfig = builtins.readFile ../../dotfiles/nushell/jj-completions.nu;
    };

    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
      };
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      attachExistingSession = true;
      settings = {
        default_shell = "nu";
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
