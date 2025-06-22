{pkgs, ...}: {
  # ------------------------------------------------
  # -------------- HOME ----------------------------
  # ------------------------------------------------
  home.packages = with pkgs; [
    awscli2
    fd
    gh
    nodejs
    ripgrep
  ];
  home.stateVersion = "24.11";

  # -----------------------------------------------
  # ---------------- PROGRAMS ---------------------
  # -----------------------------------------------
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
    enableNushellIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    delta.enable = true;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Mazin Abdallah";
        email = "mezodrdr@gmail.com";
      };
    };
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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  programs.nushell = {
    enable = true;

    shellAliases = {
      cat = "bat";
      drc = "darwin-rebuild check --flake ~/nix#aarch64";
      drs = "darwin-rebuild switch --flake ~/nix#aarch64";
      lg = "lazygit";
      vim = "nvim";
    };
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

    shellAliases = {
      ".." = "cd ..";
      cat = "bat";
      drc = "darwin-rebuild check --flake ~/nix#aarch64";
      drs = "darwin-rebuild switch --flake ~/nix#aarch64";
      lg = "lazygit";
      ls = "eza";
      vim = "nvim";
    };

    syntaxHighlighting.enable = true;
  };
}
