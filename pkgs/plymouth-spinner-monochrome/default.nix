{ stdenv, logo ? null, lib, pkgs, ... }:
stdenv.mkDerivation {
  pname = "plymouth-spinner-monochrome";
  version = "1.0";
  src = ./src;
  buildPhase = lib.optionalString (logo != null) ''
    cp $src . -r
    ln -s "${pkgs.nixos-icons}/share/icons/hicolor/96x96/apps/nix-snowflake-white.png" ./share/plymouth/themes/spinner-monochrome/watermark.png
  '';

  installPhase = ''
    cp -r . $out
  '';

  meta = { platforms = lib.platforms.all; };
}
