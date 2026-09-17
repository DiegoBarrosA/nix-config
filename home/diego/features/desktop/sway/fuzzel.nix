{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.stylix) fonts;

  fuzzel-dmenu = pkgs.writeShellScriptBin "fuzzel-dmenu" ''
    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --prompt-text)
          shift
          args+=(--prompt "$1")
          ;;
        --require-match)
          shift
          ;;
        *)
          args+=("$1")
          ;;
      esac
      shift
    done
    exec ${lib.getExe pkgs.fuzzel} --dmenu "''${args[@]}"
  '';
in
{
  options.launcher = {
    dmenu = lib.mkOption {
      type = lib.types.str;
      default = "${fuzzel-dmenu}/bin/fuzzel-dmenu";
      description = ''
        Command for dmenu-style prompts: reads the choices on stdin and prints
        the selection on stdout. Label the prompt with --prompt-text, and pass
        --require-match false where arbitrary text should be accepted.
        (Both flags were tofi-isms; the fuzzel wrapper translates them.)
      '';
    };
    drun = lib.mkOption {
      type = lib.types.str;
      default = "fuzzel";
      description = "Command for the application launcher (drun mode).";
    };
  };

  config = {
    home.packages = [ fuzzel-dmenu ];

    programs.fuzzel = {
      enable = true;

      settings = {

        main = {

          # Floating box centered in the middle of the screen.
          anchor = "center";
          layer = "overlay";

          width = 70;

          lines = 12;

          prompt = "/ㅤ";

          horizontal-pad = 16;
          vertical-pad = 16;
          inner-pad = 8;

          match-mode = "fuzzy";

          # Sway already applies output scale via wayland; fuzzel's own DPI
          # detection double-scales on HiDPI outputs and renders everything huge.
          dpi-aware = "no";

          terminal = "alacritty -e";

          font = lib.mkForce "${fonts.monospace.name}:size=${toString fonts.sizes.terminal}";
          icons-enabled = false;
        };

        # Squared corners, border width matches sway's window border.
        border = {
          width = lib.mkForce config.desktop.borderWidth;
          radius = lib.mkForce 0;
          selection-radius = lib.mkForce 0;
        };
      };
    };
  };
}
