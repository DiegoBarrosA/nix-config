{
  lib,
  stdenv,
  fetchzip,
}:
stdenv.mkDerivation rec {
  pname = "invidious-companion";
  version = "unstable-2025-07-22";

  src = fetchzip {
    url = "https://github.com/iv-org/invidious-companion/releases/download/release-master/invidious_companion-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-AqxoNcZ4Rs69o/wdMwlc00DBj3V7nG/p14P47aERoAs=";
    stripRoot = false;
  };

  # Deno-compiled binaries embed code in a custom ELF section that any
  # binary modification (patchelf, strip, autoPatchelf) corrupts. The binary
  # also reads /proc/self/exe to find its embedded section, so ld.so wrappers
  # don't work either. Requires nix-ld on the host for the dynamic linker.
  dontAutoPatchelf = true;
  dontStrip = true;
  dontPatchELF = true;
  dontFixup = true;

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 invidious_companion $out/bin/invidious-companion
  '';

  meta = with lib; {
    description = "Invidious companion for handling YouTube video streams via youtube.js";
    homepage = "https://github.com/iv-org/invidious-companion";
    license = licenses.agpl3Only;
    platforms = ["x86_64-linux"];
    mainProgram = "invidious-companion";
  };
}
