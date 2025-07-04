{pkgs, config, ...}: {
  # ------------------------------------------------
  # -------------- HOME ----------------------------
  # ------------------------------------------------
  home.packages = with pkgs; [
    awscli2
    fd
    gh
    jujutsu
    nodejs
    ripgrep
  ];
  home.stateVersion = "24.11";

  # -----------------------------------------------
  # ---------------- DOTFILES ---------------------
  # -----------------------------------------------

  home.file = {
    ".config/jj" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/jj";
    };
  };

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

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/nix";
  };

  programs.nushell = {
    enable = true;

    # Completions for jj
    extraConfig = builtins.readFile ../dotfiles/nushell/jj-completions.nu;

    shellAliases = {
      cat = "bat";
      drc = "sudo darwin-rebuild check --flake ~/nix";
      drs = "sudo darwin-rebuild switch --flake ~/nix";
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
      drc = "sudo darwin-rebuild check --flake ~/nix";
      drs = "sudo darwin-rebuild switch --flake ~/nix";
      lg = "lazygit";
      ls = "eza";
      vim = "nvim";
    };

    syntaxHighlighting.enable = true;
  };
}
