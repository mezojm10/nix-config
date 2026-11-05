{...}: {
  flake.nixosModules.noctalia-greeter = {pkgs, ...}: {
    services.displayManager.noctalia-greeter = {
      enable = true;
      passwordlessSyncUsers = ["mazin"];

      cursorTheme = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
      };

      settings = {
        appearance.scheme = "Synced";

        clock = {
          date_format = "%A, %x";
          time_format = "{:%I:%M %p}";
        };

        cursor.size = 24;

        keyboard = {
          layout = "us,ara";
          numlock = true;
          options = "grp:alt_shift_toggle";
        };

        session.default = "niri";
        user.default = "mazin";
      };
    };
  };
}
