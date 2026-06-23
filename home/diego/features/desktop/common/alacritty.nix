{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;
in
{
  home.sessionVariables = {
    TERMINAL = "alacritty";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      # General settings
      general = {
        # Enable IPC socket for server/client mode
        ipc_socket = true;
        # Live config reload
        live_config_reload = true;
      };

      # Terminal settings
      terminal = {
        # Shell configuration
        shell = {
          program = "${pkgs.nushell}/bin/nu";
          args = [ "--login" ];
        };
      };

      window = {
        # decorations = "None";  # No window decorations (Sway handles this)
        opacity = 1.0;
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
          family = fontProfiles.monospace.family;
          style = "Regular";
        };
        bold = {
          family = fontProfiles.monospace.family;
          style = "Bold";
        };
        italic = {
          family = fontProfiles.monospace.family;
          style = "Italic";
        };
        bold_italic = {
          family = fontProfiles.monospace.family;
          style = "Bold Italic";
        };
        size = 20;
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

      # Complete colorscheme configuration
      colors = {
        primary = {
          background = "#${colors.base01}";
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

      # Better defaults
      selection.save_to_clipboard = true;
    };
  };
}
