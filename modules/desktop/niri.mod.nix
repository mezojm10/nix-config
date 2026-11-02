{...}: {
  flake.nixosModules.niri = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Spawned directly from niri binds and startup.
      brightnessctl
      cliphist
      fuzzel
      ghostty
      pavucontrol
      playerctl
      polkit_gnome
      swaylock
      wlogout
      wl-clipboard

      # Niri runs X11 apps (including Steam) through this when it is on PATH.
      xwayland-satellite
    ];

    programs.niri = {
      enable = true;

      # File choosers go through the GTK portal instead of pulling in Nautilus.
      useNautilus = false;
    };

    # swaylock cannot verify the password to unlock without a PAM service.
    security.pam.services.swaylock = {};

    # Battery and power information for the Quickshell bar.
    services.upower.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
