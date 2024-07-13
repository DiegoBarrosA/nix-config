{ config, pkgs, ... }:
let inherit (config.colorScheme) palette;
in {
  home = { sessionVariables = { TERMINAL = "alacritty"; }; };
  programs.alacritty = {
    package = if !pkgs.stdenv.isDarwin then pkgs.alacritty else pkgs.dummy;
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
        normal.family = "FantasqueSansM Nerd Font Mono";
        size = 19;
      };
      cursor.style.shape = "Beam";
      colors = {
        primary.foreground = "#${palette.base05}";
        primary.background = "#${palette.base00}";
        normal = {
          blue = "#${palette.base0D}";
          red = "#${palette.base0F}";
          yellow = "#${palette.base0A}";
          green = "#${palette.base0B}";
          magenta = "#${palette.base0E}";
          cyan = "#${palette.base04}";
        };
      };
    };
  };
}

