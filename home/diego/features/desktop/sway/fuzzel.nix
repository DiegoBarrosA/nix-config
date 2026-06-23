{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        dpi-aware = "no";
        prompt = "";
        font = "${config.stylix.fonts.monospace.name}:weight=regular:size=27,Font Awesome 7 Free:style=Solid:size=27";
        line-height = 35;
        width = 50;
        fields = "name,generic,comment,categories,filename,keywords";
        terminal = "alacritty";
        show-actions = "no";
        exit-on-keyboard-focus-loss = "no";
        icons-enabled = "no";
        inner-pad = 10;
        lines = 10;
        horizontal-pad = 25;
        vertical-pad = 25;
        layer = "overlay";
      };

      colors = {
        background = "${colors.base00}ff";
        text = "${colors.base05}ff";
        match = "${colors.base0C}ff";
        selection = "${colors.base00}ff";
        selection-text = "${colors.base04}ff";
        selection-match = "${colors.base0A}ff";
        border = "${colors.base02}ff";
        prompt = "${colors.base05}ff";
        input = "${colors.base05}ff";
      };

      border = {
        radius = 0;
        width = 2;
      };

      dmenu = {
        exit-immediately-if-empty = "yes";
      };
    };
  };
}
