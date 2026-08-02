{...}: {
  flake.modules.homeManager.tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      awscli2
      fd
      gh
      nodejs
      ripgrep
    ];
  };
}
