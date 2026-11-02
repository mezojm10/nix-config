{inputs, ...}: {
  # A personal Rex server for each home-manager user on Linux, running as that
  # account in the systemd user service `rex`. On darwin the Rex app runs the
  # server and ships the CLI, so the module only contributes its options there.
  flake.homeModules.rex = {
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.modules) mkIf;
    inherit (pkgs.stdenv.hostPlatform) isLinux;
  in {
    imports = singleton inputs.rex.homeManagerModules.default;

    services.rex.enable = mkIf isLinux true;

    # The server joins the tailnet as its own node, reachable from the Rex app
    # at https://<host>-rex.<tailnet>.ts.net. Only the Tailscale account that
    # signs it in can connect. The sign-in link is in `rex server status` the
    # first time the server starts.
    services.rex.tailscale.enable = mkIf isLinux true;
    services.rex.tailscale.hostname = "${osConfig.networking.hostName}-rex";

    # home-manager does not manage ~/.ssh/config here, so the NixOS module below
    # installs the guard in /etc/ssh/ssh_config instead.
    programs.rex.sshGuard = false;
  };

  flake.nixosModules.rex = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) filterAttrs mapAttrs;
    inherit (lib.modules) mkAfter mkIf;

    rexUsers =
      config.home-manager.users
      |> filterAttrs (_: {services, ...}: services.rex.enable);

    rex = inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.rex;
  in {
    # The user service stops at logout, ending every session. Lingering starts
    # it at boot and keeps it running while logged out.
    users.users = rexUsers |> mapAttrs (_: _: {linger = true;});

    # Rex terminals set TERM=xterm-rex, which remote hosts cannot resolve. The
    # guard makes ssh announce xterm-256color unless the host is listed in
    # ~/.config/rex/terminfo-hosts, and does nothing outside a Rex terminal.
    programs.ssh.extraConfig = mkIf (rexUsers != {}) <| mkAfter "Include ${rex}/share/rex/ssh_config.d/50-rex.conf";
  };
}
