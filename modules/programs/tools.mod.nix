{...}: {
  flake.homeModules.tools = {pkgs, ...}: {
    nixpkgs.allowedUnfreePackages = [
    ];

    home.packages = with pkgs; [
      awscli2
      bitwarden-cli
      devenv
      fastfetch
      fd
      gh
      mosh
      nodejs
      ripgrep
    ];
  };
}
