{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
  inherit (config.stylix) fonts;
in
{
  home.sessionVariables = {
    TERMINAL = "alacritty";
  };

  programs.alacritty = {
    enable = true;
    settings = {

      general = {

        ipc_socket = true;

        live_config_reload = true;
      };

      terminal = {

        shell = {
          program = "${pkgs.nushell}/bin/nu";
          args = [ "--login" ];
        };
      };

      window = {

        opacity = 0.6;
        padding = {
          x = 15;
          y = 15;
        };
        dynamic_padding = true;
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      font = {
        normal = {
          family = fonts.monospace.name;
          style = "Regular";
        };
        bold = {
          family = fonts.monospace.name;
          style = "Bold";
        };
        italic = {
          family = fonts.monospace.name;
          style = "Italic";
        };
        bold_italic = {
          family = fonts.monospace.name;
          style = "Bold Italic";
        };
        size = fonts.sizes.terminal;
      };

      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
        blink_interval = 500;
      };

      mouse = {
        hide_when_typing = true;
      };

      colors = {

        transparent_background_colors = true;

        primary = {
          background = "#${colors.base00}";
          foreground = "#${colors.base05}";
        };
        cursor = {
          text = "#${colors.base00}";
          cursor = "#${colors.base05}";
        };
        vi_mode_cursor = {
          text = "#${colors.base00}";
          cursor = "#${colors.base0D}";
        };
        selection = {
          text = "#${colors.base00}";
          background = "#${colors.base0D}";
        };
        normal = {
          black = "#${colors.base00}";
          red = "#${colors.base08}";
          green = "#${colors.base0B}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base0C}";
          white = "#${colors.base05}";
        };
        bright = {
          black = "#${colors.base03}";
          red = "#${colors.base08}";
          green = "#${colors.base0B}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base0C}";
          white = "#${colors.base07}";
        };
        dim = {
          black = "#${colors.base01}";
          red = "#${colors.base08}";
          green = "#${colors.base0B}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base0C}";
          white = "#${colors.base04}";
        };
      };

      keyboard.bindings = [
        {
          key = "F";
          mods = "Command|Shift";
          action = "ToggleFullscreen";
        }
      ];

      selection.save_to_clipboard = true;
    };
  };
}
