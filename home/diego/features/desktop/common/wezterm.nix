{ config, pkgs, ... }:
let inherit (config.colorscheme) colors;
in {
  home = { sessionVariables = { TERMINAL = "wezterm"; }; };
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      -- Pull in the wezterm API
      local wezterm = require 'wezterm'

      -- This table will hold the configuration.
      local config = {}
      -- In newer versions of wezterm, use the config_builder which will
      -- help provide clearer error messages
      if wezterm.config_builder then
        config = wezterm.config_builder()
      end

      -- This is where you actually apply your config choices

      -- For example, changing the color scheme:
       
      config.color_scheme = 'default'
      config.font = wezterm.font 'Fantasque Sans Mono'
      config.font_size = 20.0

      config.hide_tab_bar_if_only_one_tab = true
      -- and finally, return the configuration to wezterm
      return config
       
    '';
    colorSchemes = {
      default = {
        ansi = [
          "#${colors.base00}"
          "#${colors.base08}"
          "#${colors.base0B}"
          "#${colors.base0A}"
          "#${colors.base0D}"
          "#${colors.base0E}"
          "#${colors.base0C}"
          "#${colors.base07}"
        ];
        brights = [

          "#${colors.base00}"
          "#${colors.base08}"
          "#${colors.base0B}"
          "#${colors.base0A}"
          "#${colors.base0D}"
          "#${colors.base0E}"
          "#${colors.base0C}"
          "#${colors.base07}"
        ];
        background = "#${colors.base00}";
        cursor_bg = "#${colors.base01}";
        cursor_border = "#${colors.base0C}";
        cursor_fg = "#${colors.base0D}";
        foreground = "#${colors.base05}";
        selection_bg = "#${colors.base03}";
        selection_fg = "#${colors.base00}";
      };
    };
  };
}
