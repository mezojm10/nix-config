{pkgs, ...}: {
  # Allow specific unfree packages on a per-package basis.
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "1password"
      "raycast"
    ];

  # GUI applications. nix-darwin rsyncs these into /Applications/Nix Apps as real
  # bundles (not symlinks), so Spotlight and Raycast index them.
  #
  # NOT MANAGED HERE -- install these by hand from the vendor .dmg/.pkg.
  # Deliberately left out, not forgotten. Sizes are the nix closure cost:
  #   - Visual Studio Code (~834M)
  #   - Bruno              (~712M)
  #   - Google Chrome      (~706M)
  #   - Discord            (~642M)
  #   - Firefox            (~487M)
  #   - Stremio            (no darwin package in nixpkgs at all)
  # The five sized apps all self-update, which nix cannot do -- a store-installed
  # copy only changes on `nix flake update`. Because bundles are copied rather than
  # symlinked, anything listed below also costs disk twice: once in /nix/store and
  # once in /Applications/Nix Apps.
  environment.systemPackages = with pkgs; [
    _1password-gui
    emacs30
    maccy
    racket
    raycast
    vlc-bin
  ];

  fonts.packages = with pkgs; [
    iosevka
    jetbrains-mono
    nerd-fonts.hack
  ];

  # Nix settings
  nix = {
    enable = false;
    # gc = {
    #   automatic = true;
    #   interval = [
    #     {
    #       Hour = 0;
    #       Minute = 0;
    #     }
    #   ];
    #   options = "--delete-older-than 7d";
    # };
    #
    # optimise = {
    #   automatic = true;
    #   interval = [
    #     {
    #       Hour = 0;
    #       Minute = 0;
    #     }
    #   ];
    # };

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
