{
  config,
  lib,
  pkgs,
  ...
}:
let

  enableKanshi = lib.attrByPath [ "rubi" "desktop" "manageKanshi" ] true config;

  kanshiSwitch = pkgs.writeShellScriptBin "kanshi-switch" ''
    PROFILE="$1"
    case "$PROFILE" in
      single|docked|triple)
        kanshictl switch "$PROFILE"
        ;;
      *)
        echo "Usage: kanshi-switch <single|docked|triple>"
        echo ""
        echo "Connected outputs:"
        swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | .name + "  " + .make + " " + .model'
        exit 1
        ;;
    esac
  '';

  displayModeUI = pkgs.writeShellScriptBin "display-mode-selector" ''
    #!/usr/bin/env bash
    CHOICE=$(printf "Single (Laptop)\nDocked (Samsung)\nTriple (All Monitors)" | ${config.launcher.dmenu} --prompt-text "display")
    [ -z "$CHOICE" ] && exit
    case "$CHOICE" in
      "Single (Laptop)")
        kanshi-switch single
        notify-send "Display" "Single monitor mode"
        ;;
      "Docked (Samsung)")
        kanshi-switch docked
        notify-send "Display" "Docked mode (Samsung)"
        ;;
      "Triple (All Monitors)")
        kanshi-switch triple
        notify-send "Display" "Triple monitor mode"
        ;;
    esac
  '';
in
lib.mkMerge [
  (lib.mkIf enableKanshi {
    home.packages = [
      kanshiSwitch
      displayModeUI
    ];

    services.kanshi = {
      enable = true;

      settings = [

        {
          profile.name = "triple";
          profile.outputs = [
            {
              criteria = "eDP-1";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "DP-1";
              position = "2240,0";
              scale = 1.0;
            }
            {
              criteria = "DP-9";
              position = "4800,0";
              scale = 1.0;
            }
          ];
        }

        {
          profile.name = "docked";
          profile.outputs = [
            {
              criteria = "eDP-1";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "DP-1";
              position = "2240,0";
              scale = 1.0;
            }
          ];
        }

        {
          profile.name = "single";
          profile.outputs = [
            {
              criteria = "eDP-1";
              position = "0,0";
              scale = 1.0;
            }
          ];
        }
      ];
    };

  })
]
