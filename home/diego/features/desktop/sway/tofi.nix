{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  inherit (config.stylix) fonts;

  app-launcher = pkgs.writeShellScriptBin "app-launcher" ''
    #!/usr/bin/env bash
    CMD=$(${lib.getExe' pkgs.tofi "tofi-drun"})
    [ -z "$CMD" ] && exit 0
    swaymsg exec -- "$CMD"
  '';
in
{
  options.launcher = {
    dmenu = lib.mkOption {
      type = lib.types.str;
      default = "tofi";
      description = ''
        Command for dmenu-style prompts: reads the choices on stdin and prints
        the selection on stdout. Label the prompt with --prompt-text, and pass
        --require-match false where arbitrary text should be accepted.
      '';
    };
    drun = lib.mkOption {
      type = lib.types.str;
      default = "app-launcher";
      description = "Command for the application launcher (drun mode).";
    };
  };

  config = {
    home.packages = [ app-launcher ];

    programs.tofi = {
      enable = true;

      settings = {

        width = "100%";
        height = "100%";
        padding-top = "25%";
        padding-bottom = "20%";
        padding-left = "35%";
        padding-right = "30%";

        num-results = 0;

        scale = true;

        font = lib.mkForce "${fonts.sansSerif.name}, Font Awesome 7 Free Solid, Font Awesome 7 Brands";
        font-size = lib.mkForce (fonts.sizes.terminal + 8);

        hide-cursor = false;

        prompt-text = " ";
        prompt-padding = 25;

        text-cursor = true;
        fuzzy-match = true;

        drun-launch = false;
        terminal = "alacritty -e";

        result-spacing = 5;

        outline-width = 0;

        border-color = lib.mkForce "#${colors.base00}ff";

        background-color = lib.mkForce "#${colors.base00}ff";

        default-result-background = lib.mkForce "#${colors.base00}ff";

        alternate-result-background = lib.mkForce "#${colors.base00}ff";

        prompt-background = lib.mkForce "#${colors.base00}ff";

        selection-color = lib.mkForce "#${colors.base00}ff";
        selection-background = lib.mkForce "#${colors.base04}a0";
        selection-background-corner-radius = 0;
        selection-padding = 10;

      };
    };
  };
}
