{...}: {
  flake.homeModules.zellij = {config, ...}: {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      attachExistingSession = true;
    };

    home.file.".config/zellij" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/zellij";
    };
  };
}
