{...}: {
  flake.homeModules.tools = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = [
      "1password-cli"
    ];

    home.packages = with pkgs; [
      _1password-cli
      awscli2
      fd
      gh
      nodejs
      ripgrep
      secretspec
    ];
  };
}
