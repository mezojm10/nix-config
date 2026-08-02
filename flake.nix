{
  description = "Mazin's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      # Which systems perSystem is instantiated for (formatter, devShells).
      systems = ["aarch64-darwin" "x86_64-linux"];
      # Auto-import every top-level module under ./modules.
      # All feature files live there as flake-parts modules.
      imports = [
        (inputs.import-tree ./modules)
        # Enable the flake.modules.<class>.<aspect> storage for deferred modules.
        inputs.flake-parts.flakeModules.modules
      ];

      # Per-system flake outputs kept here since they aren't features.
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devShells = {
          default = pkgs.mkShell {buildInputs = [pkgs.nixd];};
        };
      };
    };
}
