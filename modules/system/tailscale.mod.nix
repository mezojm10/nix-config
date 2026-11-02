{lib, ...}: let
  inherit (lib.lists) singleton;
in {
  # Tailscale, with Tailscale SSH: tailscaled answers SSH on port 22 of the
  # machine's tailnet address and authenticates through the tailnet's identity
  # and ACLs, so no sshd or authorized keys are needed. Log in once with
  # `sudo tailscale up`.
  flake.nixosModules.tailscale = {...}: {
    services.tailscale = {
      enable = true;

      # Direct (non-relayed) WireGuard connections on UDP 41641.
      openFirewall = true;

      extraSetFlags = singleton "--ssh";
    };
  };
}
