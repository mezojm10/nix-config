{inputs}: {
  # Build a darwin system whose root is the `default` aggregate; a host just
  # supplies host-specific overrides.
  darwinSystem = hostName: module: {
    flake.darwinConfigurations.${hostName} = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";

      modules = [
        inputs.self.darwinModules.default

        module

        {
          networking.hostName = hostName;
        }
      ];
    };
  };

  # Generic NixOS host builder (used for the non-darwin systems in Phase 2).
  nixosSystem = self: hostName: module: {
    flake.nixosConfigurations.${hostName} = self.nixosSystem {
      modules = [
        inputs.self.nixosModules.default

        module

        {
          networking.hostName = hostName;
        }
      ];
    };
  };
}
