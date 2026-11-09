{...}: {
  flake.homeModules.doom = {config, ...}: {
    # Doom's private config (DOOMDIR) lives in the dotfiles repo and is symlinked
    # out of the store, so edits take effect after `doom sync` without a rebuild.
    # The framework itself is a manual git checkout at ~/.config/emacs (see
    # modules/core/home.mod.nix, which puts its bin/ on PATH).
    home.file.".config/doom" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/doom";
    };
  };
}
