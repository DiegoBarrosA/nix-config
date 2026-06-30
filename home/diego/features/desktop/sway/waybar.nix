{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;

  # Convert hex color (e.g., "#82aaff") to decimal RGB value
  hexToDec =
    c:
    let
      hexMap = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
    in
    hexMap.${lib.toLower c} or 0;

  # Convert two hex characters to decimal
  hexPairToDec =
    pair:
    let
      c1 = builtins.substring 0 1 pair;
      c2 = builtins.substring 1 1 pair;
      v1 = hexToDec c1;
      v2 = hexToDec c2;
    in
    v1 * 16 + v2;

  # Extract RGB components from hex color #RRGGBB
  hexToRgb =
    hex:
    let
      # Remove # if present
      cleanHex = lib.toLower (
        if builtins.substring 0 1 hex == "#" then
          builtins.substring 1 (builtins.stringLength hex - 1) hex
        else
          hex
      );
      r = hexPairToDec (builtins.substring 0 2 cleanHex);
      g = hexPairToDec (builtins.substring 2 2 cleanHex);
      b = hexPairToDec (builtins.substring 4 2 cleanHex);
    in
    {
      r = toString r;
      g = toString g;
      b = toString b;
    };

  base04-rgb = hexToRgb colors.base04;
  # Transparent highlight for sway workspace buttons (focused / hover).
  accentWorkspaceBg = "rgba(${base04-rgb.r}, ${base04-rgb.g}, ${base04-rgb.b}, 0.3)";
  accentWorkspaceBgLow = "rgba(${base04-rgb.r}, ${base04-rgb.g}, ${base04-rgb.b}, 0.1)";

  # Package waybar custom scripts as native Nix packages (in PATH)
  tailscale-status = pkgs.writeShellScriptBin "tailscale-status" (
    builtins.readFile ./tailscale-status.sh
  );
  syncthing-status = pkgs.writeShellScriptBin "syncthing-status" (
    builtins.readFile ./syncthing-status.sh
  );
  cobalto-status = pkgs.writeShellScriptBin "cobalto-status" (builtins.readFile ./cobalto-status.sh);
  tray-tooltip = pkgs.writeShellScriptBin "tray-tooltip" (builtins.readFile ./tray-tooltip.sh);
  services-tooltip = pkgs.writeShellScriptBin "services-tooltip" (
    builtins.readFile ./services-tooltip.sh
  );
  worldclock = pkgs.writeShellScriptBin "worldclock" (builtins.readFile ./worldclock.sh);

  # Decode a \uXXXX escape to the actual Unicode character
  u = code: builtins.fromJSON ''"\u${code}"'';
in
{
  home.packages = [
    tailscale-status
    syncthing-status
    cobalto-status
    tray-tooltip
    services-tooltip
    worldclock
  ];

  programs.waybar = {
    enable = true;

    systemd = {
      enable = true;
      targets = [ "sway-session.target" ];
    };

    settings = [
      {
        layer = "top";
        position = "top";
        height = 36;
        spacing = 0;
        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [
        ];
        modules-right = [
          "group/services"
          "sway/language"
          "pulseaudio"
          "network"
          "battery"
          "custom/worldclock"
        ];

        "sway/workspaces" = {
          disable-scroll = false;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "0" = "";
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "6" = "";
            "7" = "";
            "8" = "";
          };
          persistent-workspaces = {
            "0" = [ ];
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "4" = [ ];
          };
        };

        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };

        "sway/window" = {
          max-length = 50;
        };

        tray = {
          icon-size = 18;
          spacing = 10;
        };

        "custom/tray-toggle" = {
          exec = "${tray-tooltip}/bin/tray-tooltip";
          interval = 5;
          return-type = "json";
        };

        "custom/worldclock" = {
          exec = "${worldclock}/bin/worldclock";
          interval = 30;
          return-type = "json";
          on-click = "xdg-open http://localhost:8384";
        };

        cpu = {
          format = "${u "f2db"} {usage}%";
          tooltip = true;
          interval = 2;
        };

        memory = {
          format = "${u "f538"} {}%";
          tooltip-format = "{used:0.1f}G / {total:0.1f}G";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [ "${u "f185"}" ];
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}";
          format-charging = "${u "f0e7"}";
          format-plugged = "${u "f1e6"}";
          format-icons = [
            "${u "f244"}"
            "${u "f243"}"
            "${u "f242"}"
            "${u "f241"}"
            "${u "f240"}"
          ];
        };

        network = {
          format-wifi = "${u "f1eb"}";
          format-ethernet = "${u "f796"}";
          format-disconnected = "${u "f071"} Disconnected";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}";
        };

        pulseaudio = {
          format = "{icon}";
          format-bluetooth = "${u "f294"}";
          format-muted = "${u "f6a9"}";
          format-icons = {
            headphone = "${u "f025"}";
            default = [
              "${u "f026"}"
              "${u "f027"}"
              "${u "f028"}"
            ];
          };
          on-click = "alacritty -e ncpamixer";
        };

        "group/services" = {
          orientation = "horizontal";
          drawer = {
            transition-duration = 300;
            transition-left-to-right = false;
          };
          modules = [
            "custom/tray-toggle"
            "tray"
            "custom/tailscale"
            "custom/cobalto"
            "custom/syncthing"
          ];
        };

        "custom/tailscale" = {
          exec = "${tailscale-status}/bin/tailscale-status";
          interval = 15;
          return-type = "json";
        };

        "custom/cobalto" = {
          exec = "${cobalto-status}/bin/cobalto-status";
          interval = 30;
          on-click = "xdg-open https://jellyfin.minerales.network";
          return-type = "json";
        };

        "custom/syncthing" = {
          exec = "${syncthing-status}/bin/syncthing-status";
          interval = 10;
          on-click = "xdg-open http://localhost:8384";
          return-type = "json";
        };
      }
    ];

    style = ''
      /* Colorscheme: ${config.colorscheme.type} */

      /* Reset GTK styling that might leak in */
      * {
        font-family:  "Jost*","Font Awesome 7 Brands", "Font Awesome 7 Free Solid";
        font-size: 18px;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background-color: #${colors.base00};
        color: #${colors.base05};
        border: none;
        border-radius: 0;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      window#waybar #workspaces button {
        padding: 0 8px;
        background-image: none;
        border: none;
        border-radius: 0;
        box-shadow: none;
        outline: none;
        text-shadow: none;
        border-image: none;
        background-color: transparent;
        color: #${colors.base04};
        -gtk-icon-effect: none;
      }

      window#waybar #workspaces button * {
        text-shadow: none;
      }

      window#waybar #workspaces button.urgent:not(.focused),
      window#waybar #workspaces button.active.urgent:not(.focused) {
        background-color: #${colors.base08};
        color: #${colors.base00};
        box-shadow: none;
      }

      window#waybar #workspaces button.urgent:not(.focused) *,
      window#waybar #workspaces button.active.urgent:not(.focused) * {
        color: #${colors.base00};
      }

      window#waybar #workspaces button:hover {
        background-color: ${accentWorkspaceBgLow};
        background-image: none;
        color: #${colors.base05};
        box-shadow: none;
      }

      window#waybar #workspaces button.focused,
      window#waybar #workspaces button.focused *,
      window#waybar #workspaces button.focused label,
      window#waybar #workspaces button.active,
      window#waybar #workspaces button.active * {
        color: #${colors.base04};
      }

      window#waybar #workspaces button.focused,
      window#waybar #workspaces button.active {
        background-color: ${accentWorkspaceBg};
        background-image: none;
        box-shadow: none;
      }

      #mode {
        background-color: #${colors.base0E};
        color: #${colors.base00};
        padding: 0 10px;
      }

      #window {
        color: #${colors.base04};
        padding: 0 10px;
      }

      #battery,
      #cpu,
      #memory,
      #backlight,
      #network,
      #pulseaudio,
      #language,
      #tray,
      #custom-syncthing,
      #custom-tailscale,
      #custom-cobalto,
      #custom-services-toggle,
      #custom-tray-toggle,
      #custom-worldclock {
        padding: 0 12px;
        color: #${colors.base05};
      }

      #custom-worldclock {
        font-weight: 500;
      }

      #battery.warning:not(.charging) {
        color: #${colors.base09};
      }

      #battery.critical:not(.charging) {
        background-color: #${colors.base0F};
        color: #${colors.base00};
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink {
        to {
          background-color: #${colors.base00};
          color: #${colors.base0F};
        }
      }

      #cpu {
        color: #${colors.base0C};
      }

      #memory {
        color: #${colors.base0E};
      }

      #backlight {
        color: #${colors.base0A};
      }

      #network.disconnected {
        color: #${colors.base0F};
      }

      #pulseaudio.muted {
        color: #${colors.base03};
      }

      #tray {
        background-color: #${colors.base01};
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #${colors.base0F};
      }

      #custom-syncthing {
        padding: 0 12px;
      }

      #custom-syncthing.ok {
        color: #${colors.base0B};
      }

      #custom-syncthing.syncing {
        color: #${colors.base0A};
      }

      #custom-syncthing.error {
        color: #${colors.base08};
      }

      #custom-tailscale {
        padding: 0 8px;
      }

      #custom-tailscale.connected {
        color: #${colors.base0B};
      }

      #custom-tailscale.disconnected {
        color: #${colors.base0A};
      }

      #custom-tailscale.error {
        color: #${colors.base08};
      }

      #custom-cobalto {
        padding: 0 8px;
      }

      #custom-cobalto.ok {
        color: #${colors.base0B};
      }

      #custom-cobalto.degraded {
        color: #${colors.base0A};
      }

      #custom-cobalto.offline {
        color: #${colors.base08};
      }

      #group-services {
        padding: 0 4px;
      }

      #custom-services-toggle {
        color: #${colors.base04};
        padding: 0 8px;
      }

      #group-tray-expand {
        padding: 0 4px;
      }

      #custom-tray-toggle {
        color: #${colors.base04};
        padding: 0 8px;
      }

      tooltip {
        background-color: #${colors.base00};
        border: 1px solid #${colors.base0D};
        border-radius: 4px;
      }

      tooltip label {
        color: #${colors.base05};
      }
    '';
  };
}
