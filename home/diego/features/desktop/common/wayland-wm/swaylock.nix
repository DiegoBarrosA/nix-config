{ config, pkgs, ... }:

let inherit (config.colorscheme) colors;
in
{
  home.packages = [ pkgs.swaylock-effects ];
  programs.swaylock = {
    settings = {
      effect-blur = "7x5";
      fade-in = 1;
      screenshots = true;
      font = config.fontProfiles.regular.family;
      font-size = 48;
      grace=1;

      
      line-uses-inside = true;
      disable-caps-lock-text = true;
      indicator-caps-lock = true;
      indicator-radius = 150;
      indicator-thickness=10;
      indicator-idle-visible = true;
      effect-vignette="0.5:0.5";
      hide-keyboard-layout = true;

      ring-color = "#${colors.base02}";
      inside-wrong-color = "#${colors.base08}";
      ring-wrong-color = "#${colors.base08}";
      key-hl-color = "#${colors.base0B}";
      bs-hl-color = "#${colors.base08}";
      ring-ver-color = "#${colors.base09}";
      inside-ver-color = "#${colors.base09}";
      inside-color = "#${colors.base01}";
      text-color = "#${colors.base07}";
      text-clear-color = "#${colors.base01}";
      text-ver-color = "#${colors.base01}";
      text-wrong-color = "#${colors.base01}";
      text-caps-lock-color = "#${colors.base07}";
      inside-clear-color = "#${colors.base0C}";
      ring-clear-color = "#${colors.base0C}";
      inside-caps-lock-color = "#${colors.base09}";
      ring-caps-lock-color = "#${colors.base02}";
      separator-color = "#${colors.base02}";
    };
  };
}
