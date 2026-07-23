# claude-desktop — Anthropic's desktop app, extracted from their official .deb.
# Not in nixpkgs; fetched directly from downloads.claude.ai apt repo.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libGL,
  libuuid,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  libseccomp,
  libcap_ng,
  systemd,
  xdg-utils,
}:

let
  version = "1.17377.1";
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-9L14VFIAh3tZEXmDjeeteld99u0uhFlp3SVpDvxchcc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libGL
    libuuid
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    libseccomp
    libcap_ng
    systemd
  ];

  unpackPhase = ''
    # dpkg-deb calls tar with -p which tries to restore the setuid bit on
    # chrome-sandbox and fails in the Nix sandbox. Unpack manually instead.
    ar x $src
    tar xf data.tar.* --no-same-permissions
  '';

  installPhase = ''
    runHook preInstall

    # App lives in usr/lib/claude-desktop in the deb
    mkdir -p $out/lib/claude-desktop
    cp -r usr/lib/claude-desktop/. $out/lib/claude-desktop/

    # Desktop entry and icons
    mkdir -p $out/share
    cp -r usr/share/. $out/share/ 2>/dev/null || true

    # Wrapper: autoPatchelfHook fixes the bundled electron binary;
    # makeWrapper puts xdg-utils on $PATH for xdg-open etc.
    mkdir -p $out/bin
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}

    runHook postInstall
  '';

  # autoPatchelfHook handles the bundled electron so we don't need to list
  # every transitive dep — just the direct ones above.
  autoPatchelfIgnoreMissingDeps = [
    "libEGL_nvidia.so.0"
    "libGLESv2_nvidia.so.2"
    "libGLX_nvidia.so.0"
    "libnvidia*.so.*"
    "libvulkan.so.1"
  ];

  meta = {
    description = "Anthropic's Claude desktop application";
    homepage = "https://claude.ai";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
