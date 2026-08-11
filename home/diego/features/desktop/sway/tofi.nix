{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  inherit (config.stylix) fonts;

  # tofi-drun prints the command line of the selected entry rather than running
  # it (see drun-launch below), so something has to spawn it. Handing it to sway
  # keeps the app parented to the compositor instead of to the launcher.
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
        # Percentages resolve against the output tofi opens on, so one config is
        # fullscreen on the laptop panel and on every external monitor without
        # the per-monitor character maths fuzzel needed.
        width = "40%";
        height = "40%";
        padding-top = 30;
        padding-bottom = 30;
        padding-left = 30;
        padding-right = 30;

        # Capped rather than 0 ("fill the window"), because a list that runs to
        # the bottom edge cannot be centred.
        num-results = 25;

        # Scale by the output's scaling factor rather than its physical DPI, so
        # tofi looks identical wherever it is launched.
        scale = true;

        font = lib.mkForce fonts.monospace.name;
        font-size = lib.mkForce 16;

        hide-cursor = false;
        # tofi strips whitespace from config-file values, so a trailing space in
        # prompt-text is lost and the prompt would sit flush against the input.
        # prompt-padding gives the gap instead, which also keeps every
        # --prompt-text call site free of trailing-space trickery.
        prompt-text = "~";
        # prompt-padding = 25;
        # tofi draws from the window's top-left outwards and has no alignment
        # option, so centring means padding in from the edges. These are
        # percentages of the output, so the text lands in the middle on any
        # monitor. 40% splits the difference between a short prompt (a 6-row
        # block centres at 43%) and a full 11-row launcher list (36%), leaving
        # either shape within ~50px of dead centre on the laptop panel.
        text-cursor = true;
        fuzzy-match = true;

        # With drun-launch, tofi hands the entry to glib, which has no reliable
        # way to find a terminal on NixOS and so breaks Terminal=true entries.
        # Printing instead lets `terminal` prepend alacritty; app-launcher runs
        # the result.
        drun-launch = false;
        terminal = "alacritty -e";

        result-spacing = 5;
        border-width = 2;
        outline-width = 0;
        border-color = lib.mkForce "#${colors.base0D}ff";

        background-color = lib.mkForce "#${colors.base00}ff";

        default-result-background = lib.mkForce "#${colors.base00}ff";

        alternate-result-background = lib.mkForce "#${colors.base00}ff";

        prompt-background = lib.mkForce "#${colors.base00}ff";

        selection-color = lib.mkForce "#${colors.base0D}ff";
        selection-background = lib.mkForce "#${colors.base00}ff";

      };
    };
  };
}
