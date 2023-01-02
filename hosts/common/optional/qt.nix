{ config, lib, pkgs, ... }: {
  qt5.style = "gtk2";
  qt5.enable = true;
  qt5.platformTheme = "gtk2";
}
