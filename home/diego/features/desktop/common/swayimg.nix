{ config, ... }: let
  colors = config.colorscheme.colors;
in {
  programs.swayimg = {
    enable = true;
    settings.general.overlay = "yes";
  };
  # Themed swayimg config
  xdg.configFile."swayimg/config" = {
    text = ''
      background=#${colors.base00}
      foreground=#${colors.base05}
      info=#${colors.base0D}
      font=monospace 10
      overlay=yes
    '';
  };

  xdg.mimeApps.defaultApplications = {
    "image/avif" = [ "swayimg.desktop" ];
    "image/bmp" = [ "swayimg.desktop" ];
    "image/gif" = [ "swayimg.desktop" ];
    "image/jpeg" = [ "swayimg.desktop" ];
    "image/png" = [ "swayimg.desktop" ];
    "image/svg+xml" = [ "swayimg.desktop" ];
    "image/tiff" = [ "swayimg.desktop" ];
    "image/webp" = [ "swayimg.desktop" ];
    "image/x-icns" = [ "swayimg.desktop" ];
    "image/x-icon" = [ "swayimg.desktop" ];
    "image/x-xcf" = [ "swayimg.desktop" ];
  };
}
