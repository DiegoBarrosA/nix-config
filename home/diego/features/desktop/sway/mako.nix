{ config, ... }:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;
in
{
  services.mako = {
    enable = true;
    settings = {
      font = "${fontProfiles.regular.family} 14";
      max-visible = 5;
      sort = "-time";
      layer = "overlay";
      anchor = "top-center";
      margin = "10";
      padding = "12";
      width = 350;
      height = 120;
      border-size = 2;
      border-radius = 0;
      icons = 1;
      icon-path = "/usr/share/icons/Papirus-Dark";
      max-icon-size = 48;
      default-timeout = 5000;
      ignore-timeout = 0;
      background-color = "#${colors.base00}FA";
      text-color = "#${colors.base05}";
      border-color = "#${colors.base02}";
      progress-color = "over #${colors.base0C}";

      "urgency=low" = {
        background-color = "#${colors.base00}FA";
        text-color = "#${colors.base04}";
        border-color = "#${colors.base01}";
        default-timeout = 3000;
      };

      "urgency=normal" = {
        background-color = "#${colors.base00}FA";
        text-color = "#${colors.base05}";
        border-color = "#${colors.base0D}";
        default-timeout = 5000;
      };

      "urgency=critical" = {
        background-color = "#${colors.base0F}";
        text-color = "#${colors.base00}";
        border-color = "#${colors.base08}";
        default-timeout = 0;
      };

      # Volume/brightness OSD: compact, fast, replaces itself via synchronous hint
      "category=volume" = {
        default-timeout = 1500;
        height = 60;
        border-color = "#${colors.base0C}";
      };

      "category=brightness" = {
        default-timeout = 1500;
        height = 60;
        border-color = "#${colors.base0A}";
      };
    };
  };
}
