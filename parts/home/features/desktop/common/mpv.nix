{ ... }:
{
  flake.modules.homeManager.desktop-common-mpv =
{ config, pkgs, ... }: {
  programs.mpv = {
    enable = true;
    scripts = [ ];
    config = {
      hwdec = "vaapi";
    };
  };
};
}
