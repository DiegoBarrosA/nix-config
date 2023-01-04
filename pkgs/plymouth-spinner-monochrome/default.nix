{ stdenv, logo ? null, lib, pkgs, ... }: stdenv.mkDerivation {
  pname = "plymouth-spinner-monochrome";
  version = "1.0";
  src = ./src;
  buildPhase = lib.optionalString (logo != null) ''
    cp $src . -r
    ln -s "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake.png" ./share/plymouth/themes/spinner-monochrome/watermark.png
  '';

  installPhase = ''
    cp -r . $out
  '';

  meta = {
    platforms = lib.platforms.all;
  };
}
