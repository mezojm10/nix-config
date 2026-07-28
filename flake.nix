{
  description = "Mazin's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    darwin,
    nixpkgs,
    home-manager,
    ...
  }: let
    darwin-system = import ./system/darwin.nix {inherit inputs username;};
    username = "mazinabdallah";

    devShellPackages = pkgs:
      with pkgs; [
        nixd
      ];

    mkDevShell = system: {
      default = let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        pkgs.mkShell {
          buildInputs = devShellPackages pkgs;
        };
    };
  in {
    darwinConfigurations = {
      Mazins-MacBook-Air = darwin-system "aarch64-darwin";
      x86_64 = darwin-system "x86_64-darwin";
    };

    formatter = {
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
    };

    devShells = {
      aarch64-darwin = mkDevShell "aarch64-darwin";
      x86_64-darwin = mkDevShell "x86_64-darwin";
      x86_64-linux = mkDevShell "x86_64-linux";
    };
  };
}
