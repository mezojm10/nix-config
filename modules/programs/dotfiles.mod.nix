{...}: {
  flake.homeModules.dotfiles = {config, ...}: {
    home.file = {
      ".config/aerospace" = {
        source = ../../dotfiles/aerospace;
      };
    };

    programs.aerospace = {
      enable = true;
    };

    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/nix";
    };
  };
}
