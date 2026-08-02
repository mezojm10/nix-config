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
}
