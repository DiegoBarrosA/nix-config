{ config, pkgs, pkgs-unstable, ... }: {
  programs.obs-studio = {
    enable = true;
    plugins = [ pkgs.obs-studio-plugins.wlrobs ];

  };
}
