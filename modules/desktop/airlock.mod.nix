{inputs, ...}: let
  # `astra-airlock --sync` shells out to `python3` and imports
  # `caelestia.utils.scheme`. sudo resets PATH/PYTHONPATH, so give the binary
  # both in a wrapper instead of relying on the caller's environment.
  #
  # The plugin hardcodes /usr/share/{wayland-sessions,xsessions}, which do not
  # exist on NixOS, so it falls back to a built-in Hyprland entry and greetd
  # restarts the greeter after login. Patch in the NixOS path.
  #
  # The monitor wrapper limits the greeter to the external output when one is
  # connected, falling back to all outputs (the internal panel) otherwise.
  mkAirlock = pkgs: let
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (pkgs) lib;
    python = pkgs.python3.withPackages (ps: [ps.materialyoucolor ps.pillow]);
    caelestiaCli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default;

    monitorScript = pkgs.writeShellScript "astra-airlock" ''
      outputs=$(${lib.getExe pkgs.wlr-randr} --json 2>/dev/null || true)
      external=$(printf '%s' "$outputs" | ${lib.getExe pkgs.jq} -r '
        [.[]
         | select(.enabled == true)
         | select((.name | test("^(eDP|LVDS)")) | not)
         | .name][0] // empty')

      if [ -n "$external" ]; then
        exec "''${0%/*}/.astra-airlock-env" --only "$external" "$@"
      fi

      exec "''${0%/*}/.astra-airlock-env" "$@"
    '';
  in
    pkgs.airlock.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];

      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace plugin/src/sessiondiscovery.cpp \
            --replace-fail \
            'parseDirectory(QStringLiteral("/usr/share/wayland-sessions"), QStringLiteral("Wayland"));' \
            'parseDirectory(QStringLiteral("/run/current-system/sw/share/wayland-sessions"), QStringLiteral("Wayland"));
          parseDirectory(QStringLiteral("/usr/share/wayland-sessions"), QStringLiteral("Wayland"));'
        '';

      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram $out/bin/astra-airlock \
            --prefix PATH : ${lib.makeBinPath [python pkgs.jq pkgs.wlr-randr]} \
            --prefix PYTHONPATH : "${caelestiaCli}/${python.sitePackages}"

          mv $out/bin/astra-airlock $out/bin/.astra-airlock-env
          cp ${monitorScript} $out/bin/astra-airlock
          chmod +x $out/bin/astra-airlock
        '';
    });
in {
  flake.homeModules.airlock = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # The greeter runs as the `greeter` user and cannot read the home
      # directory, so copy the active scheme into its cache whenever
      # Caelestia writes a new one.
      systemd.user = {
        paths.airlock-scheme = {
          Unit.Description = "Watch the Caelestia scheme for Airlock";

          Path = {
            PathChanged = "${config.home.homeDirectory}/.local/state/caelestia/scheme.json";
            PathExists = "${config.home.homeDirectory}/.local/state/caelestia/scheme.json";
          };

          Install.WantedBy = ["graphical-session.target"];
        };

        services.airlock-scheme = {
          Unit.Description = "Copy the Caelestia scheme to the Airlock greeter";

          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.sudo} -n ${lib.getExe (mkAirlock pkgs)} --sync";
          };
        };
      };
    };
  };

  flake.nixosModules.airlock = {
    lib,
    pkgs,
    ...
  }: {
    services.displayManager.airlock = {
      enable = true;
      package = mkAirlock pkgs;
      syncDynamicScheme.enable = true;
    };
  };
}
