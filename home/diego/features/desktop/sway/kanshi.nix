{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Default true unless rubi.desktop.manageKanshi is false (Niri-only users).
  enableKanshi = lib.attrByPath [ "rubi" "desktop" "manageKanshi" ] true config;

  # Script to switch display profiles by reloading kanshi
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

  # UI for switching display modes
  displayModeUI = pkgs.writeShellScriptBin "display-mode-selector" ''
    #!/usr/bin/env bash
    CHOICE=$(printf "Single (Laptop)\nDocked (Samsung)\nTriple (All Monitors)" | fuzzel --dmenu --prompt "display ")
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
        # NOTE: Do NOT add global (non-profile) `output.status = "disable"`
        # directives here. Global output directives are applied on top of every
        # matched profile, so a global disable for DP-1/DP-9 overrides a profile
        # that enables them (this is what killed the Samsung display in docked
        # mode). Instead, each profile explicitly disables the outputs it does
        # not use.

        # Profiles ordered most-specific first — first matching profile wins
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
