{...}: {
  flake.darwinModules.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      iosevka
      jetbrains-mono
      nerd-fonts.hack
    ];
  };
}
