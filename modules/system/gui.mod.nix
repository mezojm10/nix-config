{...}: {
  flake.darwinModules.gui = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = ["raycast"];

    # GUI applications. nix-darwin rsyncs these into /Applications/Nix Apps as
    # real bundles (not symlinks), so Spotlight and Raycast index them.
    #
    # NOT MANAGED HERE -- install these by hand from the vendor .dmg/.pkg.
    #   Visual Studio Code, Bruno, Google Chrome, Discord, Firefox, Stremio.
    environment.systemPackages = with pkgs; [
      emacs-macport
      maccy
      raycast
      vlc-bin
    ];
  };
}
