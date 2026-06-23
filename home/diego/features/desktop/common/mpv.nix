{ config, pkgs, ... }: {
  programs.mpv = {
    enable = true;
    scripts = [ ];
    config = {
      hwdec = "vaapi";
    };
  };
}
