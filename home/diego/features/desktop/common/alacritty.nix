{ config, pkgs, ... }:
let inherit (config.colorscheme) colors;
in {
  home = { sessionVariables = { TERMINAL = "alacritty"; }; };
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        option_as_alt = "OnlyLeft";
        decorations = "buttonless";
        padding = {
          x = 15;
          y = 15;
        };
      };
      mouse.hide_when_typing = true;
      keyboard.bindings = [{
        key = "F";
        mods = "Command|Shift";
        action = "ToggleFullscreen";
      }];
      font = {
        normal.family = "Fantasque Sans Mono";
        size = 19;
      };
      cursor.style.shape = "Beam";
      colors = {
        primary.foreground = "#${colors.base05}";
        primary.background = "#${colors.base00}";
        normal = {
          blue = "#${colors.base0D}";
          red = "#${colors.base0F}";
          yellow = "#${colors.base0A}";
          green = "#${colors.base0B}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base04}";
        };
      };
    };
  };
}
