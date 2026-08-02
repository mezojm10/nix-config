{lib, ...}: {
  flake.modules.darwin.gui = {
    pkgs,
    lib,
    ...
  }: {
    # Allow specific unfree packages on a per-package basis.
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "raycast"
      ];

    # GUI applications. nix-darwin rsyncs these into /Applications/Nix Apps as
    # real bundles (not symlinks), so Spotlight and Raycast index them.
    #
    # NOT MANAGED HERE -- install these by hand from the vendor .dmg/.pkg.
    #   Visual Studio Code, Bruno, Google Chrome, Discord, Firefox, Stremio.
    environment.systemPackages = with pkgs; [
      emacs30
      maccy
      raycast
      vlc-bin
    ];
  };
}
