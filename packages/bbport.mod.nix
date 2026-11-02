{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.strings) hasSuffix;
in {
  # Native Bloodborne port (GTK4 launcher + Vulkan runtime); the derivation is
  # in ./bbport because it is a package of its own, not module glue. The
  # condition reads `system` rather than `pkgs`: deciding which options exist
  # from `pkgs` recurses in flake-parts' perSystem transposition.
  perSystem = {
    pkgs,
    system,
    ...
  }:
    optionalAttrs (hasSuffix "-linux" system) {
      packages.bbport = pkgs.callPackage ./bbport {};
    };
}
