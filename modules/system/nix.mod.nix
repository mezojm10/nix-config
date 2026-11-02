{...}: {
  flake.darwinModules.nix = {...}: {
    # Nix itself is installed/managed outside nix-darwin; client settings live
    # in the flake's `nixConfig` instead.
    nix.enable = false;
  };

  flake.nixosModules.nix = {...}: {
    # The flake itself uses `|>`, so rebuilding needs pipe-operators enabled.
    nix.settings.experimental-features = ["nix-command" "flakes" "pipe-operators"];

    nix.settings.trusted-users = ["@wheel"];

    # Weekly garbage collection, keeping generations from the last month.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
