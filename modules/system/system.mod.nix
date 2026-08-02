{inputs, ...}: {
  # Aggregate the darwin-only system features into a `system` group that hosts
  # (or the `default` runtime) can pull in as one unit.
  flake.darwinModules.system = {
    imports = [
      inputs.self.darwinModules.defaults
      inputs.self.darwinModules.fonts
      inputs.self.darwinModules.gui
      inputs.self.darwinModules.nix
    ];
  };
}
