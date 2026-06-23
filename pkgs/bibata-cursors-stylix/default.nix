{ pkgs, lib, colors ? null, ... }:

let
  variant = "Bibata-Modern-Classic";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "bibata-cursors-stylix";
  version = "2.0.7";

  buildInputs = [ pkgs.bibata-cursors ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/icons/Bibata-Stylix
    cp -r ${pkgs.bibata-cursors}/share/icons/${variant}/* $out/share/icons/Bibata-Stylix/
    substituteInPlace $out/share/icons/Bibata-Stylix/index.theme \
      --replace "${variant}" "Bibata-Stylix"
  '';

  meta = {
    description = "Bibata cursor (Modern-Classic variant) for Stylix";
    homepage = "https://github.com/ful1e5/Bibata_Cursor";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
