{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
  cairo,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "windows";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "RadioNoiseE";
    repo = "windows";
    tag = "v${finalAttrs.version}";
    hash = "sha256-svzCT+dwzXIbGKWsKBodsuf5YeqW3DJjEfx7IkA8Ie0=";
  };

  # mouse support (hover to highlight, click to select, click empty space or
  # right click to dismiss); upstream issue RadioNoiseE/windows#5
  patches = [ ./mouse-support.patch ];

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];
  buildInputs = [
    wayland
    wayland-protocols
    libxkbcommon
    cairo
  ];

  # the Makefile has no install target
  installPhase = ''
    runHook preInstall
    install -Dm755 windows -t $out/bin
    install -Dm644 windows.1 -t $out/share/man/man1
    runHook postInstall
  '';

  meta = {
    description = "Expose-style window overview and selection for Wayland compositors";
    homepage = "https://github.com/RadioNoiseE/windows";
    license = lib.licenses.gpl3Only;
    mainProgram = "windows";
    platforms = lib.platforms.linux;
  };
})
