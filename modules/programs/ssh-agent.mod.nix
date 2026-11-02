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
  }: let
    askpass = pkgs.writeShellApplication {
      name = "caelestia-askpass";
      runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.socat];

      /*
      bash
      */
      text = ''
        prompt="''${1:-Password:}"
        socket="''${XDG_RUNTIME_DIR:-}/caelestia-askpass.sock"

        if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -S "$socket" ]; then
          echo "caelestia-askpass: Caelestia shell is not running" >&2
          exit 1
        fi

        response=$(
          jq -cn --arg prompt "$prompt" '{prompt: $prompt}' \
            | timeout 300 socat -t 290 - "UNIX-CONNECT:$socket,shut-none" 2>/dev/null \
            || true
        )

        secret=$(jq -r '.response // empty' <<<"$response")

        if [ -z "$secret" ]; then
          exit 1
        fi

        printf '%s\n' "$secret"
      '';
    };
  in {
    # `enableAskPassword` defaults to xserver being enabled, so without this
    # NixOS exports an empty SSH_ASKPASS and ssh never finds the prompt.
    # /etc/caelestia-askpass is stable across rebuilds, so a changed script
    # does not need a new login to update SSH_ASKPASS.
    environment.etc."caelestia-askpass".source = "${askpass}/bin/caelestia-askpass";

    programs.ssh = {
      enableAskPassword = true;
      askPassword = "/etc/caelestia-askpass";
    };

    # Use the askpass program even when a passphrase is requested from a
    # terminal; "prefer" still falls back to the tty when DISPLAY is unset.
    environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

    # GCR's agent cannot sign with PKCS#11 keys, and its socket unit resets
    # SSH_AUTH_SOCK, so leave agent duties to OpenSSH's ssh-agent.
    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
  };
}
