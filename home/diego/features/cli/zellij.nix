{ config, pkgs, lib, ... }:
let inherit (config.colorscheme) colors;
in {
  programs.zellij = {
    enable = true;
    settings = {
      simplified_ui = true;
      theme = "default";
      themes = {
        default = {
          fg = "#${colors.base05}";
          bg = "#${colors.base00}";
          black = "#${colors.base00}";
          red = "#${colors.base0F}";
          green = "#${colors.base0B}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base04}";
          white = "#${colors.base05}";
          orange = "#${colors.base09}";
        };
      };
    };
  };
}
