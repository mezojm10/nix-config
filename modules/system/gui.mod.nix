{
  inputs,
  lib,
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkMerge;
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

    # KDE apps (Dolphin, Ark) read services, QML modules and thumbnailers by
    # XDG lookup, so link all of share/ into the system profile.
    environment.pathsToLink = singleton "/share";

    # For CLI tools that open URLs (gh, jj, etc.).
    environment.sessionVariables.BROWSER = getExe config.programs.helium.package;

    environment.systemPackages = with pkgs; [
      easyeffects
      emacs-pgtk
      foliate
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      kdePackages.ark
      kdePackages.dolphin
      vlc
    ];

    # Defaults via the system-wide mimeapps.list: Helium for web links, Foliate
    # for ebooks.
    xdg.mime.defaultApplications = mkMerge [
      (genAttrs [
        "application/xhtml+xml"
        "text/html"
        "x-scheme-handler/about"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
      ] (_: "helium.desktop"))

      (genAttrs [
        "application/epub+zip"
        "application/x-mobipocket-ebook"
        "application/vnd.amazon.mobi8-ebook"
        "application/x-fictionbook+xml"
        "application/x-zip-compressed-fb2"
        "application/vnd.comicbook+zip"
      ] (_: "com.github.johnfactotum.Foliate.desktop"))
    ];

    programs.helium.enable = true;
  };
}
