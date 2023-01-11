{ config, lib, pkgs, ... }:
let
  inherit (pkgs.lib) optionals optional;
  in
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
        position = "top";
        modules-left = [ "sway/workspaces" ];
        modules-center = [ "sway/window" ];
        gtk-layer-shell = true;
        modules-right = [
          # "bluetooth"
          # "pulseaudio"
          # "network"
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
          format = "{:%a %d %b %H:%M}";
   format-calendar= "<span color='#ecc6d9'><b>{}</b></span>";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
tray = {
    "icon-size" = "${ toString config.gtk.font.size}";
        "spacing"= 1;
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
        mpd = {
          "format" =
            "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ";
          "format-disconnected" = "Disconnected ";
          "format-stopped" =
            "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
          "interval" = 10;
          "consume-icons" = { "on" = " "; };
          "random-icons" = {
            "off" = ''<span color="#f53c3c"></span> '';
            "on" = " ";
          };
          "repeat-icons" = { "on" = " "; };
          "single-icons" = { "on" = "1 "; };
          "state-icons" = {
            "paused" = "";
            "playing" = "";
          };
          "tooltip-format" = "MPD (connected)";
          "tooltip-format-disconnected" = "MPD (disconnected)";
        };
        "sway/workspaces" = {

          sort-by-coordinates = false;

          sort-by-number = true;
          format = "{name}";
          on-click = "activate";
          # format-icons = {
          #   "1" = "1";
          #   "2" = "2";
          #   "3" = "3";
          #   "4" = "4";
          #   "11" = "";
          #   "12" = "";
          #   "13" = "";
          #   "urgent" = "";
          #   "default" = "";
          # };
           persistent_workspaces = {
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
                                       min-width: 45px;

                                    }
                                    #window {
                                      padding: 5px 5px 0px 5px;

            	background: transparent;
            }
                                    tooltip {
                                       font-family:"${config.fontProfiles.regular.family}";
                                       background: #${colors.base00};
                                     border: 2px solid #${colors.base01};
                                     }
                                    #workspaces button {
                                       font-family: "${config.fontProfiles.regular.family}","Font Awesome 6 Free Solid","Font Awesome 6 Brands","FantasqueSansMono Nerd Font";
                                       font-size: 1.1em;
                                       background-color: #${colors.base00};
                                       color: #${colors.base05};
                                       margin: 2px;

                                       padding:0px 0px 0px 0px;
                                    }
                        #idle_inhibitor,
                        #pulseaudio,
                        #network
                  {

                                    font-family:"Font Awesome 6 Free Solid";
                                       padding:10px 0px 10px 0px;
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
                                    #clock {
                                      background-color: #${colors.base00};
                                      padding:5px 10px 5px 10px;
                                       font: ${
                                         toString (config.gtk.font.size + 1)
                                       }pt "${config.fontProfiles.regular.family}";
                                    }
                              #battery {

                                       font-family: "Font Awesome 6 Free Solid";

                              }
      #mpd {

                                       font-family: "Jost*","Font Awesome 6 Free Solid";
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
    '';
  };
}
