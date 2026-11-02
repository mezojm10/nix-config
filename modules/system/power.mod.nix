{...}: {
  # Power profiles exposed over D-Bus and applied through the firmware's
  # platform_profile (low-power, balanced, performance). Switch with
  # `powerprofilesctl set <profile>` or bind it in the desktop.
  flake.nixosModules.power = {...}: {
    services.power-profiles-daemon.enable = true;
  };
}
