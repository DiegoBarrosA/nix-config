{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-fresh
    hunspell
    hunspellDicts.es_CL
    hunspellDicts.en_US
  ];
}
