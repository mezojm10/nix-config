{...}: {
  flake.homeModules.agents = {...}: {
    nixpkgs.allowedUnfreePackages = ["claude-code"];

    programs.claude-code = {
      enable = true;
    };

    programs.opencode = {
      enable = true;
    };
  };
}
