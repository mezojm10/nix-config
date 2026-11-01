{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.lists) singleton;

  # The account names. They must stay literal attrs keys -- home-manager's
  # per-user config is keyed by name, which cannot be derived at eval time.
  # On darwin, `system.primaryUser` is then derived from that account.
  darwinUser = "mazinabdallah";
  nixosUser = "mazin";

  # Every registered home feature, injected into the primary user below. We do
  # this here (not via ncc's `home.extraModules`, which is hjem-only) so the
  # whole home config is reusable for a NixOS host later.
  homeModules = attrValues config.flake.homeModules;
in let
  # The full darwin "runtime": primary user derivation, home-manager wiring,
  # and the darwin-only system features. These are attrsets (not module
  # functions) so they close over `inputs` instead of demanding it as an arg,
  # which darwin evaluation would not provide. Everything except `default`
  # itself composes the runtime, including `commonModules` like `unfree`.
  default = {
    imports = inputs.self.darwinModules
      |> (mods: removeAttrs mods ["default"])
      |> attrValues;
  };

  home = {
    users.users.${darwinUser}.home = "/Users/${darwinUser}";

    imports = singleton inputs.home-manager.darwinModules.home-manager;

    # useGlobalPkgs off so home-manager evaluates its own nixpkgs, letting
    # home features set nixpkgs.config (e.g. allowedUnfreePackages).
    home-manager.useGlobalPkgs = false;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-backup";
    home-manager.extraSpecialArgs = {inherit inputs;};
    home-manager.users.${darwinUser} = {
      imports = homeModules;
      home = {
        username = darwinUser;
        homeDirectory = "/Users/${darwinUser}";
      };
    };
  };

  primary-user = {config, lib, ...}: let
    inherit (lib.attrsets) attrNames filterAttrs;
    inherit (lib.lists) head;
    inherit (lib.strings) hasPrefix;
  in {
    system.primaryUser = config.users.users
      |> filterAttrs (_: {home, ...}: home != null && hasPrefix "/Users/" home)
      |> attrNames
      |> head;
  };

  # ---- NixOS (Linux) counterparts: same home features, Linux paths

  nixos-home = {
    imports = singleton inputs.home-manager.nixosModules.home-manager;

    users.users.${nixosUser} = {
      isNormalUser = true;
      home = "/home/${nixosUser}";
      extraGroups = ["networkmanager" "tss" "wheel"];
    };

    home-manager.useGlobalPkgs = false;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-backup";
    home-manager.users.${nixosUser} = {
      imports = homeModules;
      home = {
        username = nixosUser;
        homeDirectory = "/home/${nixosUser}";
      };
    };
  };

  nixos = {
    imports = inputs.self.nixosModules
      |> (mods: removeAttrs mods ["default"])
      |> attrValues;
  };
in {
  flake.darwinModules.default = default;
  flake.darwinModules.home = home;
  flake.darwinModules.primary-user = primary-user;

  flake.nixosModules.default = nixos;
  flake.nixosModules.home = nixos-home;
}
