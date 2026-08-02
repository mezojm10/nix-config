{
  inputs,
  lib,
  ...
}: let
  inherit (import ../lib/systems.nix {inherit inputs;}) nixosSystem;
in {
  imports = [
    (nixosSystem "example-nixos" {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "26.05";

      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };

      boot.loader.grub = {
        enable = true;
        devices = ["/dev/sda"];
      };
    })
  ];
}
