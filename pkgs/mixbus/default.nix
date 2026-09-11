{
  lib,
  stdenv,
  autoPatchelfHook,
  mixbus-source,
  alsa-lib,
  libGL,
  libjack2,
  libpulseaudio,
  pipewire,
  libx11,
  libxext,
  libxinerama,
  libxrandr,
  libxrender,
  libxcursor,
  libxft,
  libxi,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxcb,
  libxcb-util,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  gtk2,
  glib,
  nspr,
  nss,
  pango,
  cairo,
  gdk-pixbuf,
}:

let
  version = "12.0.1";
in
stdenv.mkDerivation {
  pname = "mixbus";
  inherit version;

  src = mixbus-source;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    alsa-lib
    libGL
    libjack2
    libpulseaudio
    pipewire
    libx11
    libxext
    libxinerama
    libxrandr
    libxrender
    libxcursor
    libxft
    libxi
    libxcomposite
    libxdamage
    libxfixes
    libxcb
    libxcb-util
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    gtk2
    glib
    nspr
    nss
    pango
    cairo
    gdk-pixbuf
  ];

  unpackPhase = ''
    runHook preUnpack
    tar xf $src
    SKIP=$(awk -F'"' '/^skip=/{print $2}' Mixbus-12.0.1-x86_64.run)
    tail -n +$((SKIP + 1)) Mixbus-12.0.1-x86_64.run > Mixbus-payload.xz
    tar xf Mixbus-payload.xz
    tar xf Mixbus_x86_64-12.0.1.tar
    cd Mixbus_x86_64-12.0.1
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r bin lib etc share $out/

    mkdir -p $out/share/applications
    cat > $out/share/applications/mixbus.desktop <<'DESKTOP'
    [Desktop Entry]
    Type=Application
    Name=Mixbus 12
    GenericName=Digital Audio Workstation
    Comment=Harrison Mixbus DAW
    Exec=mixbus12
    Icon=mixbus
    Categories=AudioVideo;AudioEditing;Audio;Recorder;
    DESKTOP

    mkdir -p "$out/share/icons/hicolor/16x16/apps"
    cp "$out/share/resources/Mixbus-icon_16px.png" "$out/share/icons/hicolor/16x16/apps/mixbus.png"
    mkdir -p "$out/share/icons/hicolor/22x22/apps"
    cp "$out/share/resources/Mixbus-icon_22px.png" "$out/share/icons/hicolor/22x22/apps/mixbus.png"
    mkdir -p "$out/share/icons/hicolor/32x32/apps"
    cp "$out/share/resources/Mixbus-icon_32px.png" "$out/share/icons/hicolor/32x32/apps/mixbus.png"
    mkdir -p "$out/share/icons/hicolor/48x48/apps"
    cp "$out/share/resources/Mixbus-icon_48px.png" "$out/share/icons/hicolor/48x48/apps/mixbus.png"
    mkdir -p "$out/share/icons/hicolor/256x256/apps"
    cp "$out/share/resources/Mixbus-icon_256px.png" "$out/share/icons/hicolor/256x256/apps/mixbus.png"

    runHook postInstall
  '';

  autoPatchelfIgnoreMissingDeps = [
    "libEGL_nvidia.so.0"
    "libGLESv2_nvidia.so.2"
    "libGLX_nvidia.so.0"
    "libnvidia*.so.*"
    "libvulkan.so.1"
    "libx264.so"
    "libx265.so"
    "libavcodec.so"
    "libavformat.so"
    "libavutil.so"
    "libswresample.so"
  ];

  meta = with lib; {
    description = "Harrison Mixbus - Digital Audio Workstation based on Ardour";
    homepage = "https://www.harrisonconsoles.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mixbus12";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
