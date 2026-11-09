{...}: {
  flake.homeModules.doom = {
    config,
    pkgs,
    ...
  }: {
    # Doom's tree-sitter module compiles grammars with a C compiler at `doom
    # sync` time, so the build toolchain must be on PATH for the user.
    home.packages = [
      pkgs.gcc
      pkgs.gnumake
      pkgs.tree-sitter
    ];

    # Doom's private config (DOOMDIR) lives in the dotfiles repo and is symlinked
    # out of the store, so edits take effect after `doom sync` without a rebuild.
    # The framework itself is a manual git checkout at ~/.config/emacs (see
    # modules/core/home.mod.nix, which puts its bin/ on PATH).
    home.file.".config/doom" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/doom";
    };
  };
}
