{
  config,
  lib,
  pkgs,
  ...
}:
let
  rofi = lib.getExe config.programs.rofi.finalPackage;

  rofi-dmenu = pkgs.writeShellScriptBin "rofi-dmenu" ''
    require_match=true
    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --prompt-text)
          shift
          args+=(-p "$1")
          ;;
        --require-match)
          shift
          require_match="$1"
          ;;
        *)
          args+=("$1")
          ;;
      esac
      shift
    done
    [ "$require_match" = "true" ] && args+=(-no-custom)
    exec ${rofi} -dmenu "''${args[@]}"
  '';

  rofi-drun = pkgs.writeShellScriptBin "rofi-drun" ''
    exec ${rofi} -show drun
  '';
in
{
  options.launcher = {
    dmenu = lib.mkOption {
      type = lib.types.str;
      default = "${rofi-dmenu}/bin/rofi-dmenu";
      description = ''
        Command for dmenu-style prompts: reads the choices on stdin and prints
        the selection on stdout. Label the prompt with --prompt-text, and pass
        --require-match false where arbitrary text should be accepted.
      '';
    };
    drun = lib.mkOption {
      type = lib.types.str;
      default = "${rofi-drun}/bin/rofi-drun";
      description = "Command for the application launcher (drun mode).";
    };
  };
  config = {
    home.packages = [
      rofi-dmenu
      rofi-drun
    ];
  };
}
