{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.2.1";
in
stdenv.mkDerivation {
  pname = "happier";
  inherit version;

  src = fetchurl {
    url = "https://github.com/happier-dev/happier/releases/download/cli-stable/happier-v${version}-linux-x64.tar.gz";
    sha256 = "sha256-fH8EntUuvj6lXGEmqGqNfYnDC+Ng7o8pE2l5GdWpRnk=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  autoPatchelfIgnoreMissingDeps = [
    "libgcc_s.so.1"
    "libc.musl-x86_64.so.1"
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/happier $out/bin
    cp -r happier node_modules package-dist scripts $out/lib/happier/
    chmod +x $out/lib/happier/happier
    ln -s $out/lib/happier/happier $out/bin/happier
    runHook postInstall
  '';

  meta = {
    description = "Mobile, web and desktop client for AI coding agents (Claude Code, Codex, OpenCode, and more)";
    homepage = "https://github.com/happier-dev/happier";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "happier";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
