{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;

  # Decode a \uXXXX escape to the actual Unicode character
  u = code: builtins.fromJSON ''"\u${code}"'';
in
{
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
        ];
        modules-center = [
        ];
        modules-right = [
          "tray"
          "sway/language"
          "pulseaudio"
          "bluetooth"
          "network"
          "battery"
          "clock"
        ];

        "sway/workspaces" = {
          disable-scroll = false;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "5" = "";
            "6" = "";
            "7" = "";
            "8" = "";
            "9" = "";
            "focused" = "";
            "default" = "";
            "high-priority-named" = [
              "5"
              "6"
              "7"
              "8"
              "9"
              "10"
            ];
          };
          persistent-workspaces = {
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

        # macOS-style menu-bar clock: "Mon Jul 06  03:47 PM".
        # Abbreviated weekday + month, day, then 12-hour time with AM/PM.
        # Waybar's clock uses the C++ date lib, which supports %d/%I (zero
        # padded) but not %e/%l (no-pad), so leading zeros are expected.
        clock = {
          interval = 1;
          format = "{:%a %b %d  %I:%M %p}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "";
            on-scroll = 1;
            format = {
              months = "<span color='#${colors.base0D}'><b>{}</b></span>";
              days = "<span color='#${colors.base05}'>{}</span>";
              weekdays = "<span color='#${colors.base0A}'><b>{}</b></span>";
              today = "<span color='#${colors.base08}'><b>{}</b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
          };
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
          format-charging = "${u "e55b"}";
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

        bluetooth = {
          # Icons: f294 = bluetooth-b (brand). Empty format-off/disabled hides
          # the module when the controller is off, so it only shows when active.
          format = "${u "f294"}";
          format-on = "${u "f294"}";
          format-off = "";
          format-disabled = "";
          format-connected = "${u "f294"}";
          format-connected-battery = "${u "f294"} {device_battery_percentage}%";
          format-no-controller = "";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{status}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "overskride";
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
        background-color: #${colors.base01};
        background-image: none;
        color: #${colors.base05};
        box-shadow: none;
      }

      window#waybar #workspaces button.focused,
      window#waybar #workspaces button.focused *,
      window#waybar #workspaces button.focused label,
      window#waybar #workspaces button.active,
      window#waybar #workspaces button.active * {
        color: #${colors.base0D};
      }

      window#waybar #workspaces button.focused,
      window#waybar #workspaces button.active {
        background-color: #${colors.base01};
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
      #bluetooth,
      #language,
      #tray {
        padding: 0 12px;
        color: #${colors.base05};
      }

      #clock {
        padding: 0 12px;
        color: #${colors.base05};
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

      #bluetooth.connected {
        color: #${colors.base0D};
      }

      #bluetooth.discovering,
      #bluetooth.discoverable,
      #bluetooth.pairable {
        color: #${colors.base0A};
      }

      #bluetooth.off,
      #bluetooth.disabled {
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
