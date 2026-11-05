{...}: {
  flake.homeModules.ssh-agent = {
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      services.ssh-agent.enable = true;
    };
  };

  flake.nixosModules.ssh-agent = {
    lib,
    pkgs,
    ...
  }: {
    # `enableAskPassword` defaults to xserver being enabled, so without this
    # NixOS exports an empty SSH_ASKPASS and ssh never finds the prompt.
    programs.ssh = {
      enableAskPassword = true;
      askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;
    };

    environment.systemPackages = [pkgs.kdePackages.ksshaskpass];

    # Use the askpass program even when a passphrase is requested from a
    # terminal; "prefer" still falls back to the tty when DISPLAY is unset.
    environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

    # GCR's agent cannot sign with PKCS#11 keys, and its socket unit resets
    # SSH_AUTH_SOCK, so leave agent duties to OpenSSH's ssh-agent.
    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
  };
}
