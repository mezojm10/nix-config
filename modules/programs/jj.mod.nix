{...}: {
  flake.homeModules.jj = {config, ...}: {
    programs.jujutsu = {
      enable = true;
    };

    home.file.".config/jj" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/jj";
    };
  };
}
