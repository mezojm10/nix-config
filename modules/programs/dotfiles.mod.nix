{
  flake.homeModules.dotfiles = {
    config,
    lib,
    osConfig,
    ...
  }: let
    inherit (lib.modules) mkIf;
    isDarwin = osConfig.nixpkgs.hostPlatform.isDarwin;
  in {
    home.file = {
      ".config/aerospace" = mkIf isDarwin {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/aerospace";
      };
    };

    programs.aerospace = mkIf isDarwin {
      enable = true;
    };

    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/nix";
    };
  };
}
