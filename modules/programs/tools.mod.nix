{...}: {
  flake.homeModules.tools = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = [
    ];

    home.packages = with pkgs; [
      awscli2
      bitwarden-cli
      devenv
      fd
      gh
      nodejs
      ripgrep
    ];
  };
}
