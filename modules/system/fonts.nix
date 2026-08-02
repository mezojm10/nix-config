{...}: {
  flake.modules.darwin.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      iosevka
      jetbrains-mono
      nerd-fonts.hack
    ];
  };
}
