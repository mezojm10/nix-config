{
  inputs,
  lib,
  ...
}: let
  inherit (import ../lib/systems.nix {inherit inputs;}) nixosSystem;
  inherit (lib.lists) singleton;
in {
  imports =
    singleton
    <| nixosSystem "mazins-laptop" ({
      config,
      lib,
      pkgs,
      ...
    }: let
      inherit (lib) toString;
    in {
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.allowedUnfreePackages = ["nvidia-settings" "nvidia-x11"];

      system.stateVersion = "26.05";

      time.timeZone = "Africa/Cairo";

      # BOOT
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = true;

      # Typical laptop set. Compare with `nixos-generate-config --show-hardware-config`
      # on the laptop and add anything it lists that is missing here.
      boot.initrd.availableKernelModules = ["nvme" "sd_mod" "thunderbolt" "usb_storage" "usbhid" "xhci_pci"];
      boot.kernelModules = ["kvm-intel"];

      hardware.enableRedistributableFirmware = true;

      # Intel Core i7 10th gen (Comet Lake).
      hardware.cpu.intel.updateMicrocode = true;

      # FILESYSTEMS
      # Partitions are referenced by label, so the installer must create them as
      # `mkfs.fat -F 32 -n BOOT` and `mkfs.btrfs --label nixos`, the latter with
      # the subvolumes @, @home and @nix.
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = ["subvol=@" "compress=zstd" "noatime"];
      };

      fileSystems."/home" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = ["subvol=@home" "compress=zstd" "noatime"];
      };

      fileSystems."/nix" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = ["subvol=@nix" "compress=zstd" "noatime"];
      };

      # Monthly checksum verification of the btrfs volume.
      services.btrfs.autoScrub.enable = true;

      fileSystems."/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077"];
      };

      # The NTFS games partition carried over from Windows, mounted with the
      # in-kernel ntfs3 driver. Label it once with `ntfslabel <partition> Games`.
      # NTFS has no Unix permissions, so the `users` group gets write access.
      fileSystems."/mnt/games" = {
        device = "/dev/disk/by-label/Games";
        fsType = "ntfs3";
        options = [
          "gid=${toString config.ids.gids.users}"
          "umask=0002"
          "nofail"
        ];
      };

      # ntfs-3g userspace tools (ntfsfix, ntfslabel) for maintaining that partition.
      boot.supportedFilesystems.ntfs = true;

      # GRAPHICS
      # VA-API video decoding on the Intel iGPU, which renders by default.
      hardware.graphics.extraPackages = singleton pkgs.intel-media-driver;

      services.xserver.videoDrivers = ["nvidia"];

      # GTX 1660 Ti (Turing), new enough for both the open kernel module and
      # fine-grained power management.
      hardware.nvidia = {
        open = true;

        # Power the dGPU down when idle.
        powerManagement.enable = true;
        powerManagement.finegrained = true;

        # Render on the iGPU by default; run games on the dGPU with
        # `nvidia-offload %command%` in Steam launch options.
        prime = {
          offload.enable = true;
          offload.enableOffloadCmd = true;

          # The usual addresses on Comet Lake laptops. Confirm with `lspci` on
          # the laptop, converting hex to decimal ("01:00.0" -> "PCI:1:0:0").
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    });
}
