{
  config,
  lib,
  pkgs,
  ...
}:
let

  enableKanshi = lib.attrByPath [ "rubi" "desktop" "manageKanshi" ] true config;

  profiles = [
    {
      name = "single";
      label = "Single (Laptop)";
    }
    {
      name = "docked";
      label = "Docked (Samsung)";
    }
    {
      name = "triple";
      label = "Triple (All Monitors)";
    }
  ];
  profileNames = map (p: p.name) profiles;

  kanshiSwitch = pkgs.writeShellScriptBin "kanshi-switch" ''
    PROFILE="$1"
    case "$PROFILE" in
      ${lib.concatStringsSep "|" profileNames})
        kanshictl switch "$PROFILE"
        ;;
      *)
        echo "Usage: kanshi-switch <${lib.concatStringsSep "|" profileNames}>"
        echo ""
        echo "Connected outputs:"
        swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | .name + "  " + .make + " " + .model'
        exit 1
        ;;
    esac
  '';

  displayModeUI = pkgs.writeShellScriptBin "display-mode-selector" ''
    #!/usr/bin/env bash
    CHOICE=$(printf '${lib.concatMapStringsSep "\\n" (p: p.label) profiles}\n' | ${config.launcher.dmenu} --prompt-text "display")
    [ -z "$CHOICE" ] && exit
    case "$CHOICE" in
      ${lib.concatMapStringsSep "\n      " (p: ''
        "${p.label}")
          kanshi-switch ${p.name}
          notify-send "Display" "${p.label}"
          ;;'') profiles}
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
