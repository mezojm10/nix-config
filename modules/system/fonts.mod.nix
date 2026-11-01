{...}: {
  # Shared across NixOS and Darwin via commonModules.
  commonModules.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      iosevka
      jetbrains-mono
      nerd-fonts.hack
    ];
  };
}
