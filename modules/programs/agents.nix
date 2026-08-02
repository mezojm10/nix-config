{...}: {
  flake.modules.homeManager.agents = {lib, ...}: {
    # Allow specific unfree packages on a per-package basis for home-manager.
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "claude-code"
      ];

    programs.claude-code = {
      enable = true;
    };

    programs.opencode = {
      enable = true;
    };
  };
}
