{ config, lib, pkgs, ... }:
let inherit (pkgs.lib) optionals optional;
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "graphical-session.target";
    settings = {
      primary = {
        mode = "dock";
        all-outputs = true;
        name = "ptrt-0";
        ipc = true;
        layer = "top";
        output = [ "LG Electronics LG ULTRAWIDE 0x0002A4C3" ];
        position = "left";
        modules-left = [ "sway/workspaces" ];
        gtk-layer-shell = true;
        modules-right = [
          "sway/mode"
          "tray"
          "pulseaudio"
          "network"
          "battery"
          "idle_inhibitor"
          "sway/language"
          "clock"
        ];
        battery = {
          bat = "BAT0";
          interval = 10;
          format-icons = [ "" "" "" "" "" ];
          format = "{icon}";
          tooltip-format = "%{capacity}, {time}";
        };
        clock = {
          format = ''
            {:%H
            %M}'';
          format-calendar = "<span color='#ecc6d9'><b>{}</b></span>";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
        bluetooth = {
          "format" = "";
          "format-disabled" = "";
          "format-on" = "";
          "format-off" = "";
          "format-connected" = "";
          "on-click" = "tofi-bluemenu";
        };
        tray = {
          "icon-size" = "${toString config.gtk.font.size}";
          "spacing" = 1;
        };
        network = {
          "interface" = "wlp6s0";
          "format" = "{ifname}";
          "format-wifi" = "";
          "format-ethernet" = "";
          "tooltip-format" = "{ifname} via {gwaddr}";
          "tooltip-format-wifi" = "{essid} ({signalStrength}%) ";
          "tooltip-format-ethernet" = "{ifname} ";
          "tooltip-format-disconnected" = "Disconnected";
          "max-length" = 50;
        };

        idle_inhibitor = {
          "format" = "{icon}";
          "format-icons" = {
            "activated" = "";
            "deactivated" = "";
          };
        };
        pulseaudio = {
          "format" = "{icon}";
          "format-bluetooth" = "{icon}";
          "format-muted" = "";
          "format-icons" = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [ "" "" "" ];
          };
          "scroll-step" = 1;
          "on-click" = "exec $(pkill pavucontrol || pavucontrol)";
        };
        "sway/mode" = {
          format = "  {}";
          max-length = 50;
          rotate = 90;
        };
        "hyprland/language" = {
          "format" = "";
          "format-en" = "us";
          "format-es" = "es";
          "keyboard-name" = "logitech-usb-receiver";
        };
        "sway/workspaces" = {
          sort-by-coordinates = false;
          sort-by-number = true;
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "一";
            "2" = "二";
            "3" = "三";
            "4" = "四";
            "5" = "五";
            "6" = "六";
            "7" = "七";
            "8" = "八";
            "9" = "九";
            "10" = "十";
            "11" = "";
            "12" = "";
            "13" = "";
            "14" = "";
            "19" = "";

            "20" = "";
          };
          persistent-workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "4" = [ ];
          };
        };
      };

      secondary = {
        mode = "dock";
        all-outputs = true;
        name = "lscp-0";
        ipc = true;
        layer = "top";
        output = [ "Samsung Electric Company LS27A600U HCJW500005" ];
        position = "top";
        modules-left = [ "sway/workspaces" ];
        modules-center = [ "sway/window" ];
        gtk-layer-shell = true;
        modules-right = [
          "tray"
          "sway/language"
          "sway/mode"
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "battery"
          "clock"
        ];
        battery = {
          bat = "BAT0";
          interval = 10;
          format-icons = [ "" "" "" "" "" ];
          format = "{icon}";
          tooltip-format = "%{capacity}, {time}";
        };
        clock = {
          format = "{:%a %d %b %I:%M %p }";
          format-calendar = "<span color='#ecc6d9'><b>{}</b></span>";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
        bluetooth = {
          "format" = "";
          "format-disabled" = "";
          "format-on" = "";
          "format-off" = "";
          "format-connected" = "";
          "on-click" = "tofi-bluemenu";
        };
        tray = {
          "icon-size" = "${toString config.gtk.font.size}";
          "spacing" = 1;
        };
        network = {
          "interface" = "wlp6s0";
          "format" = "{ifname}";
          "format-wifi" = "";
          "format-ethernet" = "";
          "tooltip-format" = "{ifname} via {gwaddr}";
          "tooltip-format-wifi" = "{essid} ({signalStrength}%) ";
          "tooltip-format-ethernet" = "{ifname} ";
          "tooltip-format-disconnected" = "Disconnected";
          "max-length" = 50;
        };

        idle_inhibitor = {
          "format" = "{icon}";
          "format-icons" = {
            "activated" = "";
            "deactivated" = "";
          };
        };
        pulseaudio = {
          "format" = "{icon}";
          "format-bluetooth" = "{icon}";
          "format-muted" = "";
          "format-icons" = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [ "" "" "" ];
          };
          "scroll-step" = 1;
          "on-click" = "exec $(pkill pavucontrol || pavucontrol)";
        };
        "sway/mode" = {
          format = "  {}";
          max-length = 50;
          rotate = 90;
        };
        "hyprland/language" = {
          "format" = "";
          "format-en" = "us";
          "format-es" = "es";
          "keyboard-name" = "logitech-usb-receiver";
        };
        "sway/workspaces" = {
          sort-by-coordinates = false;
          sort-by-number = true;
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "一";
            "2" = "二";
            "3" = "三";
            "4" = "四";
            "5" = "五";
            "6" = "六";
            "7" = "七";
            "8" = "八";
            "9" = "九";
            "10" = "十";
            "11" = "";
            "12" = "";
            "13" = "";
            "14" = "";
            "19" = "";
            "20" = "";
          };
          persistent-workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "4" = [ ];
          };
        };
      };
    };
    # Cheatsheet:
    # x -> all sides
    # x y -> vertical, horizontal
    # x y z -> top, horizontal, bottom
    # w x y z -> top, right, bottom, left
    style = let inherit (config.colorscheme) colors;
    in ''
      * {
      min-width: 1.8em;
      }
      .lscp-0 * {
      min-height: 1em;
      }

      tooltip {
      font-family:"${config.fontProfiles.monospace.family}";
      background: #${colors.base00};
      border: 2px solid #${colors.base01};
      }

      .lscp-0 #workspaces button {
      font-family: "Font Awesome 6 Free Solid","Font Awesome 6 Brands", "Source Han Mono";
      font-size: 1em;
      background-color: #${colors.base00};
      color: #${colors.base05};
      margin: 6px;
      padding:0.35em 0.25em 0.35em 0.25em;
      }

      .ptrt-0 #workspaces button {
      font-family: "Font Awesome 6 Free Solid","Font Awesome 6 Brands", "Source Han Mono";
      font-size: 1em;
      background-color: #${colors.base00};
      color: #${colors.base05};
      margin: 6px;
      padding:0.45em 0.25em 0.45em 0.25em;
      }

      .ptrt-0 #idle_inhibitor,
      .ptrt-0 #pulseaudio,
      .ptrt-0 #bluetooth,
      .ptrt-0 #custom-powermenu,
      .ptrt-0 #custom-launcher,
      .ptrt-0 #network,
      .ptrt-0 #custom-notification 
      {
      font-family:"Font Awesome 6 Free Solid";
      padding:0.55em 0em 0.55em 0em;
      }
      .ptrt-0 #clock {
      background-color: #${colors.base00};
      padding:0.9em 0em 0.55em 0em;
      margin-bottom:2px;
      color: #${colors.base05};
      font-family:"${config.fontProfiles.monospace.family}";
      font-size:1.2em;
      }


            
      window.lscp-0#idle_inhibitor,
      window.lscp-0#pulseaudio,
      window.lscp-0#bluetooth,
      window.lscp-0#custom-powermenu,
      window.lscp-0#custom-launcher,
      window.lscp-0#custom-notification, 
      window.lscp-0#network
      {
      font-family:"Font Awesome 6 Free Solid";
      padding:0.55em 0em 0.55em 0em;
      }
      #workspaces button.hidden {
      background-color: #${colors.base00};
      color: #${colors.base04};
      }
      #workspaces button.focused,
      #workspaces button.active {
      background-color: #${colors.base01};
      color: #${colors.base0D};
      border-radius: 10px;
      }
      #workspaces button.active {
      background-color: #${colors.base01};
      color: #${colors.base05};
      border-radius: 10px;
      }
      #bluetooth.discoverable,
      #bluetooth.discovering,
      #bluetooth.pairable,
      #bluetooth.on {
      color: #${colors.base0C};
      }
      #bluetooth.connected {
      color: #${colors.base0B};
      }
      #bluetooth.off {
      color: #${colors.base0F};
      }
      .lscp-0 #clock {

      background-color: #${colors.base00};
      padding:0.25em 0.7em 0.25em 0.55em;
      margin-bottom:2px;
      color: #${colors.base05};
      }
      #battery {
      font-family: "Font Awesome 6 Free Solid";
      }
      #idle_inhibitor.activated {
      color:#${colors.base08};
      }
      #language
      {
      color:#${colors.base0B};
      }
      #tray {
      color: #${colors.base05};
      }
      #mode {
      padding:0em 0.55em 0em 0.55em;
      color: #${colors.base0F};

                  }
    '';
  };
}
