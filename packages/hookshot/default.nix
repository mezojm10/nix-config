{
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
}: let
  inherit (lib.lists) singleton;

  pname = "hookshot";
  version = "2.3.2";

  desktopItem = makeDesktopItem {
    name = "hookshot-builder";
    desktopName = "Hookshot Builder";
    comment = "Build Ocarina of Time for PC from your own copy of the game";
    exec = "hookshot";
    icon = "hookshot";
    categories = singleton "Game";
    terminal = false;
    prefersNonDefaultGPU = true;

    actions.play = {
      name = "Play";
      exec = "hookshot --play";
      icon = "hookshot";
    };
  };
in
  appimageTools.wrapType2 (finalAttrs: {
    inherit pname version;

    src = fetchurl {
      url = "https://git.notrexed.dev/Hookshot/Hookshot/releases/download/v${version}/Hookshot-v${version}-x86_64.AppImage";
      hash = "sha256-SccfR9GdcJgabwr9USVnKAkrYeat6MyFjWYoGHp9aw4=";
    };

    extraInstallCommands =
      /*
      bash
      */
      ''
        install --mode=444 -D ${desktopItem}/share/applications/hookshot-builder.desktop \
          --target-directory "$out/share/applications"
        install --mode=444 -D ${finalAttrs.contents}/usr/share/icons/hicolor/256x256/apps/hookshot.png \
          "$out/share/icons/hicolor/256x256/apps/hookshot.png"
      '';

    meta = {
      description = "Builder for a native Ocarina of Time (Switch 2) PC port";
      homepage = "https://hookshot.notrexed.dev/";
      license = lib.licenses.gpl3Plus;
      platforms = singleton "x86_64-linux";
      mainProgram = "hookshot";
    };
  })
