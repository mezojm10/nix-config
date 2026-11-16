{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
in {
  # The upstream AppImage contains the builder and toolchain, but no game data.
  # It is only published for x86-64 Linux.
  perSystem = {
    pkgs,
    system,
    ...
  }:
    optionalAttrs (system == "x86_64-linux") {
      packages.hookshot = pkgs.callPackage ./hookshot {};
    };
}
