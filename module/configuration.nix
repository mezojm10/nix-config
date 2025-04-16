{
  # Homebrew
  homebrew = {
    enable = true;

    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [
      {
        name = "emacs-plus";
      }
      {
        name = "postgresql@16";
        restart_service = "changed";
      }
    ];

    casks = [
      "1password"
      "aerospace"
      "bruno"
      "discord"
      "firefox"
      "font-hack-nerd-font"
      "font-iosevka"
      "font-jetbrains-mono"
      "google-chrome"
      "kitty"
      "maccy"
      "raycast"
      "stremio"
      "vlc"
      "visual-studio-code"
    ]; # gui applications
  };

  # Nix settings
  nix = {
    gc = {
      automatic = true;
      interval = [
        {
          Hour = 0;
          Minute = 0;
        }
      ];
      options = "--delete-older-than 7d";
    };

    optimise = {
      automatic = true;
      interval = [
        {
          Hour = 0;
          Minute = 0;
        }
      ];
    };

    settings = {
      builders-use-substitutes = true;
      experimental-features = ["flakes" "nix-command"];
      flake-registry = builtins.toFile "null-flake-registry.json" ''{"flakes":[],"version":2}'';
      substituters = ["https://nix-community.cachix.org"];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = ["@wheel"];
      warn-dirty = false;
    };
  };

  programs.zsh.enable = true;

  # Darwin system settings
  system = {
    defaults = {
      dock.autohide = true;
      finder.FXPreferredViewStyle = "clmv";
      loginwindow.GuestEnabled = false;
      NSGlobalDomain.AppleInterfaceStyle = "Dark";
      NSGlobalDomain.KeyRepeat = 2;
    };

    keyboard.enableKeyMapping = true;
    keyboard.swapLeftCtrlAndFn = true;

    stateVersion = 6;
  };
}
