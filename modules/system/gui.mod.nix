{
  inputs,
  lib,
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
in {
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

  flake.nixosModules.gui = {
    config,
    pkgs,
    ...
  }: {
    imports = singleton inputs.helium.nixosModules.default;

    # For CLI tools that open URLs (gh, jj, etc.).
    environment.sessionVariables.BROWSER = getExe config.programs.helium.package;

    environment.systemPackages = with pkgs; [
      emacs-pgtk
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      kdePackages.ark
      kdePackages.dolphin
      vlc
    ];

    # Default browser for links, via the system-wide mimeapps.list.
    xdg.mime.defaultApplications =
      genAttrs [
        "application/xhtml+xml"
        "text/html"
        "x-scheme-handler/about"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
      ]
      (_: "helium.desktop");

    programs.helium.enable = true;
  };
}
