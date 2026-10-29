{ ... }:
{
  flake.modules.homeManager.cli-zathura =
{ pkgs, lib, ... }: let
  zathuraWithMupdf = pkgs.symlinkJoin {
    name = "zathura-with-mupdf";
    paths = [
      pkgs.zathura
      pkgs.zathuraPkgs.zathura_pdf_mupdf
    ];
  };
in {
  stylix.targets.zathura.enable = true;

  programs.zathura = {
    enable = true;
    package = zathuraWithMupdf;
    options = {
      recolor = true;
      selection-clipboard = "clipboard";
      scroll-step = 80;
      guioptions = "sv";
    };
    # Vim-style: hjkl scroll, J/K page, gg/G top/bottom, / search are built in.
    mappings = {
      "u" = "scroll half-up";
      "d" = "scroll half-down";
      "H" = "navigate previous";
      "L" = "navigate next";
      "<C-o>" = "jumplist backward";
      "<C-i>" = "jumplist forward";
    };
  };
}
;
}
