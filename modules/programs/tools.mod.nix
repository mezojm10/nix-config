{...}: {
  flake.homeModules.tools = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = [
      "1password-cli"
    ];

    home.packages = with pkgs; [
      _1password-cli
      awscli2
      devenv
      fd
      gh
      nodejs
      ripgrep
    ];
  };
}
