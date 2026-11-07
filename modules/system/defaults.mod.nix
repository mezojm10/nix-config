{...}: {
  flake.darwinModules.defaults = {...}: {
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
  };

  flake.nixosModules.defaults = {pkgs, ...}: {
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    networking.networkmanager.enable = true;

    hardware.bluetooth.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Compressed swap in RAM instead of a swap partition. Priority 100 keeps it
    # ahead of any disk-backed swap tier, which would sit at a lower value.
    zramSwap.enable = true;
    zramSwap.priority = 100;
  };
}
