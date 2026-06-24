{ pkgs, lib, ... }: let
  zathuraWithMupdf = pkgs.symlinkJoin {
    name = "zathura-with-mupdf";
    paths = [
      pkgs.zathura
      pkgs.zathuraPkgs.zathura_pdf_mupdf
    ];
  };
in {
  programs.zathura = {
    enable = true;
    package = zathuraWithMupdf;
  };
}
