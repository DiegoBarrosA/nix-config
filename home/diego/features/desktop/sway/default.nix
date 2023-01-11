{ pkgs, config, lib, ... }: {
  imports = [ ../common/wayland-wm ];
  home.packages = with pkgs; [ autotiling ];
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    systemdIntegration = true;
    extraConfig = "seat seat0 xcursor_theme ${config.gtk.cursorTheme.name} '${
        toString config.gtk.cursorTheme.size
      }' ";
    config = rec {
      modifier = "Mod4";
      terminal = "alacritty";
      menu = "tofi-drun  --prompt-text=' Launch:' | xargs swaymsg exec";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      bars = [{ command = "waybar"; }];
      input = {
        "type:keyboard" = {
          xkb_layout = "us,es";
          xkb_capslock = "disabled";
          xkb_options =
            "grp:alt_space_toggle,shift:both_capslock,caps:ctrl_modifier";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
      };
      colors = let inherit (config.colorscheme) colors;
      in {
        unfocused = {
          background = "#${colors.base00}";
          border = "${colors.base00}";
          childBorder = "#${colors.base00}";
          indicator = "${colors.base00}";
          text = "${colors.base05}";
        };
        focused = {
          background = "#${colors.base0D}";
          border = "#${colors.base0D}";
          childBorder = "#${colors.base0D}";
          indicator = "#${colors.base0D}";
          text = "${colors.base0A}";
        };
        focusedInactive = {
          background = "#${colors.base00}";
          border = "${colors.base00}";
          childBorder = "#${colors.base00}";
          indicator = "${colors.base00}";
          text = "${colors.base05}";
        };
      };
      gaps = {
        inner = 5;
        outer = 0;
        smartGaps = true;
        smartBorders = "on";
      };
      window = {
        border = 3;
        hideEdgeBorders = "smart";
      };
      output = {
        HDMI-A-1 = {
          scale = "1";
          bg =
            "/storage/var/lib/syncthing/Pictures/Anime/Landscape/wallhaven-pkrv6j.jpg fill";
        };
      };
      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
        launchOrChange = pkgs.writeShellScript "launchOrChange" ''
             #!/bin/sh
          if swaymsg -t get_tree | grep $1
          then swaymsg "workspace $2"
          else
          exec $3 & swaymsg "workspace $2"
          fi
        '';
      in {
        "${mod}+Return" = "exec ${terminal}";
        "${mod}+q" = "kill";
        "${mod}+Space" = "exec ${menu}";
        "${mod}+c" = ''
          exec clipman pick -t CUSTOM --tool-args="tofi --prompt-text=' Pick:'"
        '';

        "XF86MonBrightnessUp" = "light -A 10";

        "XF86MonBrightnessDown" = "light -U 10";
        "${mod}+s" = "exec flameshot gui";
        "${mod}+Shift+e" = "exec tofi-powermenu";
        "${mod}+${left}" = "focus left";
        "${mod}+${down}" = "focus down";
        "${mod}+${up}" = "focus up";
        "${mod}+${right}" = "focus right";
        "${mod}+Shift+${left}" = "move left";
        "${mod}+Shift+${down}" = "move down";
        "${mod}+Shift+${up}" = "move up";
        "${mod}+Shift+${right}" = "move right";
        "${mod}+r" = "mode resize";
        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+a" = "focus parent";
        "${mod}+Shift+t" = "focus mode_toggle";
        "${mod}+p" = "sticky toggle";
        "${mod}+m" = "fullscreen toggle";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+Ctrl+l" = "workspace next";
        "${mod}+Ctrl+h" = "workspace prev";

        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        "${mod}+f" = "exec ${launchOrChange} firefox  firefox";
        "${mod}+e" = "exec ${launchOrChange} pcmanfm  pcmanfm";
        "${mod}+d" =
          ''exec ${launchOrChange} emacs  "emacsclient -c -a 'emacs'" '';
        "${mod}+t" = "workspace ";
        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";
        "${mod}+minus" = "scratchpad show";
        "${mod}+underscore" = "move container to scratchpad";

      };
      modes = {

        resize = {
          h = "resize shrink width";
          l = "resize grow width";
          j = "resize shrink height";
          k = "resize grow height";
          Return = "mode default";
          Escape = "mode default";
        };

      };
      startup = [
        { command = "mako"; }
        { command = "dbus-sway-environment"; }
        { command = "autotiling"; }
        { command = "keepassxc"; }
        { command = "pcmanfm -d --no-desktop"; }
        { command = "transmission-remote-gtk"; }
        { command = "wl-paste -t text --watch clipman store"; }
        {
          command =
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        }
        { command = "systemctl --user restart waybar"; always = true; }
        {
          command =
            "wl-paste -p -t text --watch clipman store -P --histpath='~/.local/state/clipman-primary.json'";
        }
  {
    command = ''
exec swayidle -w \
	timeout 1800 'swaylock -f' \
	timeout 1805 'swaymsg "output * dpms off"' \
	resume 'swaymsg "output * dpms on"' \
before-sleep 'swaylock'        '';

        }

      ];
      assigns = {
        "" = [{ app_id = "emacs"; }];
        "" = [{ app_id = "firefox"; }];
        "" = [{ app_id = "pcmanfm"; }];
        "" = [{ app_id = "transmission-remote-gtk"; }];
      };
      floating.criteria = [{ title = "Picture-in-Picture"; }];
      window.commands = [
        {
          command = "move to scratchpad";
          criteria = { app_id = "org.keepassxc.KeePassXC"; };
        }
        {
          command = "sticky enable";
          criteria = { title = "Picture-in-Picture"; };
        }
        {
          criteria = {
            app_id = "zoom";
            title = "^zoom$";
          };
          command = "border none, floating enable";
        }
        {
          criteria = {
            app_id = "zoom";
            title = "^(Zoom|About)$";
          };
          command = "border pixel, floating enable";
        }
        {
          criteria = {
            app_id = "zoom";
            title = "Settings";
          };
          command = "floating enable, floating_minimum_size 960 x 700";
        }
        { # Open Zoom Meeting windows on a new workspace (a bit hacky)
          criteria = {
            app_id = "zoom";
            title = "Zoom Meeting(.*)?";
          };
          command =
            "workspace next_on_output --create, move container to workspace current, floating disable, inhibit_idle open";

        }
            ];
    };
  };


}
