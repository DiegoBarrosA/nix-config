{ lib, config, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (pkgs) stdenv;

in {
  programs.mpv = {
    package = mkIf stdenv.isDarwin pkgs.iina;
    enable = true;
  };
  #  home.packages = [ pkgs.jellyfin-mpv-shim];
}
