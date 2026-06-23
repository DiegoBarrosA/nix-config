{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.zellij = {
    enable = true;
    # Note: enableNushellIntegration doesn't exist in home-manager yet
    # Zellij integration is handled manually in nushell.nix via Ctrl+T keybinding
    settings = {
      default_shell = "nu";

      show_startup_tips = false;
      pane_frames = false;
      mouse_mode = true;
      simplified_ui = true;
      theme = "default";
      copy_command = "wl-copy";
      scrollback_editor = "${pkgs.helix}/bin/hx";
      copy_on_select = false;
      themes = {
        default = {
          fg = "#${colors.base05}";
          bg = "#${colors.base00}";
          black = "#${colors.base00}";
          red = "#${colors.base0F}";
          green = "#${colors.base0D}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base04}";
          white = "#${colors.base05}";

          orange = "#${colors.base0C}";
        };
      };
    };
  };
}
