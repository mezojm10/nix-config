{...}: {
  flake.nixosModules.gaming = {...}: {
    nixpkgs.allowedUnfreePackages = ["steam" "steam-unwrapped"];

    programs.steam.enable = true;
  };
}
