{ self, pkgs, ... }:

{
  # list packages installed in system profile. to search by name, run:
  # $ nix-env -qap | grep wget
  environment.systemPackages =
    with pkgs; [
      btop
      bat
      curl
      eza
      fd
      fzf
      gcc
      gh
      git
      helix
      lazygit
      neovim
      nushell
      pnpm
      python314
      starship
      wget
    ];

  environment.shellAliases = {
    vim = "nvim";
    ls = "eza";
    cat = "bat";
    ".." = "cd ..";
  };

  # homebrew
  homebrew = {
    enable = true;

    onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [
      {
        name = "emacs-plus@29";
        args = [ "--with-native-comp" ];
      }
      {
        name = "postgresql@16";
        restart_service = "changed";
      }
      "awscli"
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
  };

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Auto upgrade nix package and the daemon service.
  nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
