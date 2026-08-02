{...}: {
  flake.darwinModules.nix = {...}: {
    # Nix itself is installed/managed outside nix-darwin; client settings live
    # in the flake's `nixConfig` instead.
    nix.enable = false;
  };
}
