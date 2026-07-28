# jcode — RAM-efficient AI coding harness (pre-built binary from GitHub releases).
# https://github.com/1jehuang/jcode
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  zlib,
}:

let
  version = "0.56.0";
  sha256 = "sha256-2RGQZnFivnl6IvEmxZ/e8z17CRY4Qk927r9kC7cmHGs=";
in
stdenv.mkDerivation {
  pname = "jcode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/1jehuang/jcode/releases/download/v${version}/jcode-linux-x86_64.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    openssl
    zlib
  ];

  # The tarball contains a single binary named `jcode-linux-x86_64`.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 jcode-linux-x86_64 $out/bin/jcode
    runHook postInstall
  '';

  meta = {
    description = "The most RAM efficient AI coding harness";
    homepage = "https://jcode.sh";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "jcode";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
