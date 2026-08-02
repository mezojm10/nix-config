{...}: {
  flake.homeModules.home = {config, ...}: {
    home.stateVersion = "26.05";

    # Doom's CLI lives in its own checkout, outside the nix store, so nothing
    # puts it on PATH by default -- `doom sync` would just be "command not found".
    # zsh is the login shell, so hm-session-vars.sh carries this into zellij/nushell.
    home.sessionPath = ["${config.home.homeDirectory}/.config/emacs/bin"];
  };
}
