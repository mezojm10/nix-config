{...}: {
  flake.nixosModules.niri = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Spawned or bound by niri's built-in default config.
      alacritty
      fuzzel
      swaylock
      waybar

      # Niri runs X11 apps (including Steam) through this when it is on PATH.
      xwayland-satellite
    ];

    programs.niri.enable = true;

    # swaylock cannot verify the password to unlock without a PAM service.
    security.pam.services.swaylock = {};

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
