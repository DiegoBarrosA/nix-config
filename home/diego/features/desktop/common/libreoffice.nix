{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libreoffice-fresh
    gnumeric
    hunspell
    hunspellDicts.es_CL
    hunspellDicts.en_US
  ];
}
