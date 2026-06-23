{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs.gnomeExtensions; [
    appindicator
    blur-my-shell
    user-themes
    dash2dock-lite
    clipboard-indicator
    caffeine
    pop-shell
    just-perfection
    vitals
  ];
}
