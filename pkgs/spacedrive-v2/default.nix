{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  glib,
  libsoup_3,
  openssl,
  xdotool,
  gdk-pixbuf,
  cairo,
  pango,
  libva,
  alsa-lib,
  libGL,
}:

stdenv.mkDerivation rec {
  pname = "spacedrive-v2";
  version = "2.0.0-alpha.2";

  src = fetchurl {
    url = "https://github.com/spacedriveapp/spacedrive/releases/download/v${version}/Spacedrive-linux-x86_64.deb";
    hash = "sha256-KzRPBtyX5x4ZLlZd6SgAS/cy/7irXt7v+b3Yuq9GETo=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    glib
    libsoup_3
    openssl
    xdotool
    gdk-pixbuf
    cairo
    pango
    libva
    alsa-lib
    stdenv.cc.cc.lib
  ];

  runtimeDependencies = [ libGL ];

  unpackPhase = "dpkg-deb -x $src .";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/bin usr/lib usr/share $out/
    substituteInPlace $out/share/applications/Spacedrive.desktop \
      --replace-quiet "Exec=Spacedrive" "Exec=$out/bin/Spacedrive"
    runHook postInstall
  '';

  meta = {
    description = "Spacedrive v2 alpha, a local-first file manager (repacked upstream .deb)";
    homepage = "https://github.com/spacedriveapp/spacedrive";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "Spacedrive";
  };
}
