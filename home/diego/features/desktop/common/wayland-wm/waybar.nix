{ config, lib, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      primary = {
        mode = "dock";
        ipc = true;
        layer = "top";
        margin = "0";
        width = 1;
        position = "left";
        modules-left = [ "sway/workspaces" ];
        modules-center = [ ];
        modules-right = [
          # "bluetooth"
          # "pulseaudio"
          # "network"
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
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
        network = {
          "interface" = "enp5s0";
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
          "on-click" = "pavucontrol";
        };

        "sway/workspaces" = {

          sort-by-coordinates = false;

          sort-by-number = true;
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "6" = "";
            "7" = "";
            "8" = "";
            "9" = "";

            "10" = "";
            "urgent" = "";
            "default" = "";
          };
          persistent_workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "4" = [ ];
            "5" = [ ];
            "6" = [ ];
            "7" = [ ];
            "8" = [ ];
            "9" = [ ];
            "10" = [ ];
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
                                 min-width: 43px;
                              }
                              #window {
                                padding: 5px 0px 5px 5px;
      	background: transparent;
      }
                              tooltip {
                                 font-family:"${config.fontProfiles.regular.family}";
                                 background: #${colors.base00};
                               border: 2px solid #${colors.base01};
                               }
                              #workspaces button {
                                 font-family: "Font Awesome 6 Free Solid", "Font Awesome 6 Brands";
                                 font-size: ${toString config.gtk.font.size}pt;
                                 background-color: #${colors.base00};
                                 color: #${colors.base05};
                                 margin: 2px;
                                 padding:11px 0px 11px 0px;
                              }
                  #idle_inhibitor,
                  #pulseaudio,
                  #network
            #language
            {


                                 padding:11px 0px 11px 0px;
                  }
                              #workspaces button.hidden {
                                 background-color: #${colors.base00};
                                 color: #${colors.base04};
                              }
                              #workspaces button.focused,
                              #workspaces button.active {
                                 background-color: #${colors.base01};
                                 color: #${colors.base05};
                                 border-left: 2px solid  #${colors.base0D};
                                 border-radius: 10px;
                              }
                              #clock {
                                background-color: #${colors.base00};
                                color: #${colors.base0D};
                                padding:10px 5px 10px 5px;
                                 font: ${
                                   toString (config.gtk.font.size + 3)
                                 }pt "${config.fontProfiles.monospace.family}";
                              }
                        #battery {

                                 font-family: "Font Awesome 6 Free Solid";

                        }
    '';
  };
}
