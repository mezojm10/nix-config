{
  config,
  inputs,
  lib,
  moduleLocation,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.fixedPoints) fix;
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf;

  wrap = {
    kind,
    class ? null,
  }: name: value:
    fix (module: {
      _file = "${toString moduleLocation}#${kind}.${name}";
      key = module._file;

      ${
        if class == null
        then null
        else "_class"
      } =
        class;

      imports = singleton value;
    });
in {
  # flake-parts declares `flake.nixosModules` without a `key`, so deduplication
  # would not happen. Redeclare it ourselves.
  disabledModules = singleton "${inputs.flake-parts}/modules/nixosModules.nix";

  options.flake.nixosModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = {};
    apply = mapAttrs (wrap {
      kind = "nixosModules";
      class = "nixos";
    });
    description = "NixOS modules.";
  };

  options.flake.darwinModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = {};
    apply = mapAttrs (wrap {
      kind = "darwinModules";
      class = "darwin";
    });
    description = "Darwin modules.";
  };

  options.flake.homeModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = {};
    apply = mapAttrs (wrap {kind = "homeModules";});
    description = "Home modules.";
  };

  options.commonModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = {};
    apply = mapAttrs (wrap {kind = "commonModules";});
    description = "Modules shared between NixOS and Darwin.";
  };

  # `commonModules` are merged into every OS config so shared options (e.g.
  # nixpkgs.allowedUnfreePackages) are declared on both NixOS and Darwin.
  config.flake.nixosModules = mkMerge [config.commonModules];
  config.flake.darwinModules = mkMerge [config.commonModules];
}
