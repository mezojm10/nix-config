{...}: {
  flake.homeModules.agents = {...}: {
    # The nixpkgs claude-code wrapper defaults this to "system", which misses
    # roots the API chain needs (UNABLE_TO_GET_ISSUER_CERT_LOCALLY). Keep the
    # bundled Mozilla roots and still honor the system store.
    home.sessionVariables.CLAUDE_CODE_CERT_STORE = "bundled,system";

    nixpkgs.allowedUnfreePackages = ["claude-code"];

    programs.claude-code = {
      enable = true;
    };

    programs.opencode = {
      enable = true;
    };
  };
}
