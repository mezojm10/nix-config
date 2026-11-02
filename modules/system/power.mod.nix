{...}: {
  # Power profiles exposed over D-Bus and applied through the firmware's
  # platform_profile (low-power, balanced, performance). Powerdevil picks one per
  # power state (System Settings > Power Management); `powerprofilesctl set
  # <profile>` switches by hand.
  flake.nixosModules.power = {...}: {
    services.power-profiles-daemon.enable = true;
  };
}
