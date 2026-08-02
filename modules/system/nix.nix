{...}: {
  flake.modules.darwin.nix = {...}: {
    # Nix settings
    nix = {
      enable = false;
      # gc = {
      #   automatic = true;
      #   interval = [
      #     {
      #       Hour = 0;
      #       Minute = 0;
      #     }
      #   ];
      #   options = "--delete-older-than 7d";
      # };
      #
      # optimise = {
      #   automatic = true;
      #   interval = [
      #     {
      #       Hour = 0;
      #       Minute = 0;
      #     }
      #   ];
      # };

      settings = {
        builders-use-substitutes = true;
        experimental-features = ["flakes" "nix-command"];
        flake-registry = builtins.toFile "null-flake-registry.json" ''{"flakes":[],"version":2}'';
        substituters = ["https://nix-community.cachix.org"];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        trusted-users = ["@wheel"];
        warn-dirty = false;
      };
    };
  };
}
