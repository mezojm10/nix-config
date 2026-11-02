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
      nixpkgs.allowedUnfreePackages = ["nvidia-settings" "nvidia-x11" "stremio-linux-shell"];

      system.stateVersion = "26.05";

      time.timeZone = "Africa/Cairo";

      # BOOT
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = true;

      # From `nixos-generate-config --show-hardware-config` on the laptop.
      boot.initrd.availableKernelModules = ["ahci" "nvme" "sd_mod" "usb_storage" "usbhid" "xhci_pci"];
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

      # POWER
      # Battery conservation mode (the EC holds the charge at ~60% to slow wear)
      # is toggled from System Settings > Power Management, through powerdevil's
      # ideapad_acpi support. The EC keeps the setting across reboots.

      # APPLICATIONS
      # nixpkgs dropped `stremio` along with qt5 webengine; this is its
      # replacement Linux shell.
      environment.systemPackages = singleton pkgs.stremio-linux-shell;

      # GRAPHICS
      # VA-API video decoding on the Intel iGPU, which renders by default.
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      hardware.graphics.extraPackages = [
        pkgs.rocmPackages.clr
        pkgs.intel-media-driver
      ];

      services.xserver.videoDrivers = ["nvidia"];

      # GTX 1660 Ti (Turing), new enough for both the open kernel module and
      # fine-grained power management.
      hardware.nvidia = {
        open = true;

        # The production driver's NVENC API (13.0) is older than the one
        # nixpkgs' FFmpeg is built against (13.1), so gpu-screen-recorder cannot
        # hardware-encode monitors attached to the dGPU (the HDMI port).
        package = config.boot.kernelPackages.nvidiaPackages.latest;

        modesetting.enable = true;

        # Power the dGPU down when idle.
        powerManagement.enable = true;
        powerManagement.finegrained = true;

        nvidiaSettings = true;

        # Render on the iGPU by default; run games on the dGPU with
        # `nvidia-offload %command%` in Steam launch options.
        prime = {
          offload.enable = true;
          offload.enableOffloadCmd = true;

          # From `lspci` on the laptop, hex converted to decimal
          # ("01:00.0" -> "PCI:1:0:0").
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };

      # DDC/CI for the external monitor's brightness. brightnessctl only reaches
      # the internal panel's EC backlight, which is off while the AOC is
      # connected; the caelestia shell sets VCP 10 over ddcutil instead.
      hardware.i2c.enable = true;

      # DISPLAYS
      # DRM numbers connectors of the same type globally across GPUs in the
      # order their drivers register. The dGPU has an eDP connector of its own,
      # so when nvidia-drm wins the race the panel comes up as eDP-2 and no
      # kanshi profile below matches. Loading i915 in the initrd registers the
      # iGPU first, keeping the panel at eDP-1.
      boot.initrd.kernelModules = singleton "i915";

      # Turn the built-in panel off whenever an external monitor is connected,
      # and back on when it is unplugged. Confirm the panel's name with
      # `niri msg outputs`. Closing the lid while docked does not suspend,
      # since logind ignores the lid switch when an external display is present.
      home-manager.sharedModules = singleton {
        services.kanshi = {
          enable = true;
          settings = [
            {
              # The AOC advertises 60 Hz as its preferred mode, so pin the
              # 144 Hz mode explicitly when it is connected.
              profile.name = "aoc";
              profile.outputs = [
                {
                  criteria = "eDP-1";
                  status = "disable";
                }
                {
                  criteria = "PNP(AOC) 24G2W1G4 ATNM81A000199";
                  status = "enable";
                  mode = "1920x1080@144Hz";
                }
              ];
            }
            {
              profile.name = "docked";
              profile.outputs = [
                {
                  criteria = "eDP-1";
                  status = "disable";
                }
                {
                  criteria = "*";
                  status = "enable";
                }
              ];
            }
            {
              profile.name = "undocked";
              profile.outputs = singleton {
                criteria = "eDP-1";
                status = "enable";
              };
            }
          ];
        };

        # GAMES
        # Native Bloodborne port (packages/bbport). The GTX 1660 Ti is the only
        # card here with Vulkan 1.3 and robustBufferAccess2, so the Lutris entry
        # pins VK_DRIVER_FILES to the NVIDIA ICD; the module seeds the folders.
        programs.bbport = {
          enable = true;
          gameDir = "/mnt/games/Games/Bloodborne/game";
          userDir = "/mnt/games/Games/Bloodborne/Saves";
        };
      };
    });
}
