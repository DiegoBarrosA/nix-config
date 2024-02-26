{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation rec {
  pname = "swayshot";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {

    owner = "DiegoBarrosA";
    repo = "sway-interactive-screenshot";
    rev = "93eaa29a4ee9b650fab8156129be8c01711fedef";
    sha256 = "VNGvA8ujwjpC2rTVZKrXni2GjfiZk7AgAn4ZB4Baj2k=";

  };

  buildInputs = [ pkgs.git ];

  buildPhase = "";

  installPhase = ''
    cp  $src/sway-interactive-screenshot  $out/bin/swayshot
  '';
}
