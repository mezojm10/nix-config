{
  config,
  lib,
  ...
}: let
  unfreeModule = {
    config,
    lib,
    ...
  }: let
    inherit (lib.lists) elem;
    inherit (lib.options) mkOption;
    inherit (lib.strings) getName;
    inherit (lib.types) listOf str;
  in {
    options.nixpkgs.allowedUnfreePackages = mkOption {
      type = listOf str;
      default = [];
      description = "Unfree packages allowed by name.";
      example = ["raycast"];
    };

    config.nixpkgs.config.allowUnfreePredicate = package:
      elem (getName package) config.nixpkgs.allowedUnfreePackages;
  };
in {
  # Shared across NixOS and Darwin via commonModules.
  commonModules.unfree = unfreeModule;

  # home-manager evaluates its own nixpkgs (useGlobalPkgs = false), so the same
  # unfree option must be declared inside the home config too.
  flake.homeModules.unfree = unfreeModule;
}
