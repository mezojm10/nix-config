{...}: {
  flake.nixosModules.niri = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Spawned directly from niri binds and startup.
      brightnessctl
      ddcutil
      ghostty
      playerctl
      wl-clipboard

      # Niri runs X11 apps (including Steam) through this when it is on PATH.
      xwayland-satellite
    ];

    programs.niri = {
      enable = true;

      # File choosers go through the GTK portal instead of pulling in Nautilus.
      useNautilus = false;
    };

    # Noctalia's polkit agent handles authentication prompts; only the daemon
    # needs to be enabled here.
    security.polkit.enable = true;

    # Lets Noctalia write the GNOME interface keys that GTK apps and the
    # desktop portal read (theme, colour scheme and icon theme).
    programs.dconf.enable = true;

    # Noctalia's screen recorder plugin records through gpu-screen-recorder's
    # KMS capture. Its gsr-kms-server needs CAP_SYS_ADMIN, which this provides
    # as a setcap wrapper instead of prompting through pkexec on every
    # recording.
    programs.gpu-screen-recorder.enable = true;

    # Battery and power information for the Noctalia bar.
    services.upower.enable = true;

    # The login manager is Airlock on greetd; see `modules/desktop/airlock.mod.nix`.
  };
}
