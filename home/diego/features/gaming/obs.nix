{ pkgs, ... }: {
  programs.obs-studio.enable = true;

  programs.obs-studio.plugins = [ pkgs.obs-studio-plugins.droidcam-obs ];
}
