{lib, ...}: let
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkIf;
in {
  # KDE System Settings and its system pages (network, Bluetooth, audio, power,
  # info center) under niri, without the Plasma shell.
  flake.nixosModules.kde-settings = {pkgs, ...}: {
    # In the system profile too, so powerdevil's KAuth helpers (backlight,
    # battery conservation mode) are registered on the system bus and their
    # polkit actions are visible.
    environment.systemPackages = singleton pkgs.kdePackages.powerdevil;

    # Profiles only link allowlisted directories, and the home profile follows
    # the same list. KDE reads a lot from share/ by XDG lookup: the Network
    # page's QML (share/kcm_networkmanagement), the Breeze Dark palette (see
    # `qt` in rice.mod.nix), translations, notifications. Plasma's own module
    # links all of share/ for the same reason.
    environment.pathsToLink = singleton "/share";

    # Kirigami and other KColorScheme users read colors only from kdeglobals'
    # [Colors:*] groups, which Plasma normally copies in. Ship Breeze Dark as
    # the system-wide kdeglobals, so ~/.config/kdeglobals stays writable and
    # only overrides it.
    environment.etc."xdg/kdeglobals".source = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";

    # Plasma's power management daemon, which the Power Management page talks
    # to. It takes over idle suspend, the lid switch, and the power button from
    # logind. Under niri it cannot turn screens off (that needs KWin's DPMS
    # protocol) or see external monitors (KScreen), so its lid action also
    # fires while docked. Spelled out because powerdevil installs its own unit
    # under share/systemd/user, where NixOS does not look.
    systemd.user.services.plasma-powerdevil = {
      description = "Powerdevil";
      partOf = singleton "graphical-session.target";
      after = singleton "graphical-session.target";
      wantedBy = singleton "graphical-session.target";

      serviceConfig = {
        ExecStart = "${pkgs.kdePackages.powerdevil}/libexec/org_kde_powerdevil";
        Type = "dbus";
        BusName = "org.kde.Solid.PowerManagement";
        Restart = "always";
        Slice = "background.slice";
        TimeoutStopSec = "5sec";
      };
    };
  };

  flake.homeModules.kde-settings = {pkgs, ...}: {
    # In the home profile because home-manager's `qt` module puts that
    # profile's Qt plugin and QML directories on the search paths, which is how
    # System Settings finds the pages shipped by other packages. Open a single
    # page with e.g. `systemsettings kcm_networkmanagement`. bluez-qt,
    # kirigami-addons and libplasma (with ksvg) provide QML modules that the
    # Bluetooth, Audio and Network pages import.
    home.packages = mkIf pkgs.stdenv.hostPlatform.isLinux (with pkgs.kdePackages; [
      bluedevil
      bluez-qt
      kinfocenter
      kirigami-addons
      ksvg
      libplasma
      plasma-nm
      plasma-pa
      powerdevil
      systemsettings
    ]);
  };
}
