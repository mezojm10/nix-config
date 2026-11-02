{...}: {
  flake.nixosModules.niri = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Spawned directly from niri binds and startup.
      brightnessctl
      cliphist
      ghostty
      playerctl
      swaylock
      wl-clipboard

      # Niri runs X11 apps (including Steam) through this when it is on PATH.
      xwayland-satellite
    ];

    programs.niri = {
      enable = true;

      # File choosers go through the GTK portal instead of pulling in Nautilus.
      useNautilus = false;
    };

    # The agent itself is the Caelestia shell's polkit module; only the daemon
    # needs to be enabled here.
    security.polkit.enable = true;

    # Lets caelestia-cli write the GNOME interface keys that GTK apps and the
    # desktop portal read (theme, colour scheme and icon theme).
    programs.dconf.enable = true;

    # swaylock cannot verify the password to unlock without a PAM service.
    security.pam.services.swaylock = {};

    # caelestia-cli records the screen through gpu-screen-recorder's KMS
    # capture. Its gsr-kms-server needs CAP_SYS_ADMIN, which this provides as a
    # setcap wrapper instead of prompting through pkexec on every recording.
    programs.gpu-screen-recorder.enable = true;

    # Battery and power information for the Quickshell bar.
    services.upower.enable = true;

    # The login manager is Airlock on greetd; see `modules/desktop/airlock.mod.nix`.
  };
}
