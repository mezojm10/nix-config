{inputs}: let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in {
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

  # Generic NixOS host builder, rooted at the nixos `default` aggregate.
  nixosSystem = hostName: module: {
    flake.nixosConfigurations.${hostName} = nixosSystem {
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
