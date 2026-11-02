{
  lib,
  stdenv,
  fetchgit,
  bash,
  cmake,
  coreutils,
  ninja,
  pkg-config,
  makeWrapper,
  util-linux,
  wrapGAppsHook4,
  gobject-introspection,
  python3,
  vulkan-headers,
  vulkan-loader,
  fmt,
  boost,
  magic-enum,
  robin-map,
  vulkan-memory-allocator,
  xxhash,
  sdl3,
  zydis,
  glslang,
  spirv-headers,
  ffmpeg,
  protobuf,
  nlohmann_json,
  miniupnpc,
  openssl,
  zlib,
  libx11,
  libxcb,
  xorgproto,
  xbyak,
  wayland,
  gtk4,
  libadwaita,
  adwaita-icon-theme,
  hicolor-icon-theme,
  librsvg,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "bbport";
  version = "2.3.2";

  src = fetchgit {
    url = "https://github.com/Jgamrot/yharnam-pc";
    rev = "91f63da8a9e8ed37561aea8a3207d3aed2587598";
    fetchSubmodules = true;
    hash = "sha256-grwTgonVaeYr0owpO2+nRCDltpW9mCq+xomYQn4azNA=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    makeWrapper
    wrapGAppsHook4
    gobject-introspection
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    fmt
    boost
    magic-enum
    robin-map
    vulkan-memory-allocator
    xxhash
    sdl3
    zydis
    glslang
    spirv-headers
    ffmpeg
    protobuf
    nlohmann_json
    miniupnpc
    openssl
    zlib
    libx11
    libxcb
    xorgproto
    xbyak
    wayland
    gtk4
    libadwaita
    adwaita-icon-theme
    hicolor-icon-theme
    librsvg
  ];

  # The port's own changes to FSR-Vulkan (build.sh applies them with git apply).
  postPatch = ''
    for patch in gpu/patches/fsr-vulkan/*.patch; do
      patch --directory gpu/third_party/fsr-vulkan --strip 1 < "$patch"
    done

    # Newer Vulkan-Hpp overloads make the brace assignment ambiguous.
    substituteInPlace gpu/shadps4/video_core/renderer_vulkan/vk_frame_generation.cpp \
      --replace-fail 'size = {hudless_width, hudless_height};' \
      'size = vk::Extent2D{hudless_width, hudless_height};'
  '';

  dontConfigure = true;

  # RPATHs are set at link time and left alone: patchelf's --shrink-rpath corrupts the
  # symbol versions of the non-PIE loader.
  dontPatchELF = true;

  buildPhase = ''
    runHook preBuild

    libraryPath=${lib.makeLibraryPath finalAttrs.buildInputs}

    cmake -S gpu -B out/gpu -G Ninja \
      -D CMAKE_BUILD_TYPE=RelWithDebInfo \
      -D BB_PGO=off \
      -D BB_LTO=OFF \
      -D "CMAKE_CXX_FLAGS=-I${miniupnpc}/include/miniupnpc" \
      -D CMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,'\$ORIGIN' -Wl,-rpath,$libraryPath -L${miniupnpc}/lib -lminiupnpc"
    ninja -C out/gpu bbgpu

    mkdir --parents out/atrac9
    for source in third_party/LibAtrac9/C/src/*.c; do
      $CC -std=c99 -O2 -g -w -c "$source" -o "out/atrac9/$(basename "''${source%.c}").o"
    done
    ar rcs out/libatrac9.a out/atrac9/*.o

    read -r -a includes <<< "$(pkg-config --cflags vulkan sdl3)"
    read -r -a libraries <<< "$(pkg-config --libs vulkan sdl3)"

    # The sources CMake links into bb-probe.exe on Windows. build.sh's Linux path
    # leaves them out, and the shared runtime references them (pads, mouse camera,
    # in-game menu, effects), so the port would not link on Linux without them.
    # runtime_atlas_state.c is Windows-only: its statics are unused here.
    $CC -std=c11 -O2 -g -Wall -Wextra -Werror \
      -Wno-error=unused-function -Wno-error=unused-variable \
      -pthread -no-pie \
      "''${includes[@]}" -I. -Isrc \
      src/probe.c src/runtime*.c src/vulkan_smoke.c \
      src/cloth_rate.c src/engine_hooks.c src/engine_features.c src/pc_menu.c \
      src/rebirth.c src/ending_trace.c src/input_bindings.c src/mouse_camera.c \
      src/key_prompts.c src/menu_pointer.c src/occlusion_queries.c src/wind_pace.c \
      src/blur_kernel.c src/render_jobs.c src/effect_step_gate.c \
      src/effect_smooth_steps.c src/light_blink.c src/water_gate.c src/frame_time.c \
      out/libatrac9.a -lm \
      -Lout/gpu -lbbgpu -rdynamic \
      -Wl,-rpath,'$ORIGIN/gpu' -Wl,-rpath,"$libraryPath" \
      "''${libraries[@]}" -o out/bb-probe

    $CC -std=c11 -O2 -Wall -Wextra -Werror \
      tools/gpu_capabilities.c -Wl,-rpath,"$libraryPath" \
      "''${libraries[@]}" -o out/bb-gpu-capabilities

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    port=$out/share/bbport
    mkdir --parents "$port/bin" $out/bin $out/libexec

    cp run.sh "$port/"
    cp --recursive scripts patches launcher "$port/"
    install --mode=755 out/bb-probe "$port/bin/bb-probe"
    install --mode=755 out/bb-gpu-capabilities "$port/bin/bb-gpu-capabilities"
    install --directory "$port/bin/gpu"
    install --mode=755 out/gpu/libbbgpu.so "$port/bin/gpu/libbbgpu.so"

    # Generated files, saves and bbport.ini live outside the store. The wrappers
    # run this first, then whatever they were given.
    cat > $out/libexec/bbport-data-dir <<'SH'
    #!/bin/sh
    export BB_DATA_DIR="''${BB_DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/bbport}"
    mkdir --parents "$BB_DATA_DIR"
    exec "$@"
    SH
    chmod 755 $out/libexec/bbport-data-dir

    runHook postInstall
  '';

  # makeWrapper is called after wrapGAppsHook4 has filled gappsWrapperArgs.
  dontWrapGApps = true;

  postFixup = ''
    launcher=${python3.withPackages (ps: [ps.pygobject3])}/bin/python3
    common=(
      "''${gappsWrapperArgs[@]}"
      --set BB_PREBUILT 1
      --set PYTHON ${python3}/bin/python3
      --prefix PATH : ${lib.makeBinPath [bash coreutils util-linux python3]}
    )

    makeWrapper $out/libexec/bbport-data-dir $out/bin/bbport "''${common[@]}" \
      --add-flags "$launcher" \
      --add-flags "$out/share/bbport/launcher/bbport_launcher.py"

    makeWrapper $out/libexec/bbport-data-dir $out/bin/bbport-game "''${common[@]}" \
      --add-flags ${bash}/bin/bash \
      --add-flags "$out/share/bbport/run.sh"
  '';

  meta = {
    description = "Native Bloodborne PC port (shadPS4 renderer, Vulkan)";
    homepage = "https://github.com/Jgamrot/yharnam-pc";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    mainProgram = "bbport";
  };
})
