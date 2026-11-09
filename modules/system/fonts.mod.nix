{...}: {
  # Shared across NixOS and Darwin via commonModules.
  commonModules.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      inter
      iosevka
      jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts-color-emoji
    ];
  };
}
