{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
in
{

  xdg.configFile."zellij/layouts/dev.kdl".text = ''
    layout {
        pane split_direction="vertical" {
            pane size="22%" name="files" {
                command "yazi"
            }
            pane name="editor" focus=true {
                command "hx"
            }
            pane size="30%" name="agent"
        }
    }
  '';

  xdg.configFile."zellij/layouts/notes.kdl".text = ''
    layout {
        pane command="ekphos"
    }
  '';

  programs.zellij = {
    enable = true;

    settings = {
      default_shell = "nu";

      show_startup_tips = false;
      welcome_screen = false;
      pane_frames = false;
      mouse_mode = true;
      simplified_ui = true;
      theme = "material-darker";
      copy_command = "wl-copy";
      scrollback_editor = "${pkgs.helix}/bin/hx";
      copy_on_select = false;
      themes = {
        material-darker = {
          fg = "#${colors.base05}";

          bg = "#${colors.base01}";
          black = "#${colors.base00}";
          red = "#${colors.base08}";
          green = "#${colors.base0B}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base0C}";
          white = "#${colors.base05}";
          orange = "#${colors.base09}";
        };
      };
    };
  };
}
