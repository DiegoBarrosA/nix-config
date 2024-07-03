{ pkgs, config, lib, ... }: {
  imports = [ ../common/wayland-wm ];
  programs = {
    fish.loginShellInit = ''
      if test (tty) = "/dev/tty1"
        exec sway &> /dev/null
      end
    '';
  };
  home.packages = with pkgs; [ autotiling swayr ];
  xdg.portal = {
    enable = true;
    configPackages = [ pkgs.gnome.gnome-session ];
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    wrapperFeatures.base = true;
    systemd = {
      xdgAutostart = true;
      enable = true;
    };
    extraConfig = "seat seat0 xcursor_theme ${config.gtk.cursorTheme.name} '${
        toString config.gtk.cursorTheme.size
      }' ";
    config = rec {
      terminal = "! (alacritty msg create-window) && alacritty";
      modifier = "Mod4";
      bars = [ ];
      menu =
        "${pkgs.tofi}/bin/tofi-drun  --prompt-text=' Launch:' | xargs swaymsg exec";

      left = "h";
      down = "j";
      up = "k";
      right = "l";
      fonts = {
        names = [ "${config.fontProfiles.monospace.family}" "Source Han Mono" ];
        size = 18.0;
      };
      input = {
        "type:keyboard" = {
          xkb_layout = "us,latam";
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
          border = "#${colors.base00}";
          childBorder = "#${colors.base00}";
          indicator = "#${colors.base00}";
          text = "#${colors.base0D}";
        };
        focused = {
          background = "#${colors.base0D}";
          border = "#${colors.base0D}";
          childBorder = "#${colors.base0D}";
          indicator = "#${colors.base0D}";
          text = "#${colors.base00}";
        };
        focusedInactive = {
          background = "#${colors.base00}";
          border = "#${colors.base00}";
          childBorder = "#${colors.base00}";
          indicator = "#${colors.base00}";
          text = "#${colors.base0D}";
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
        titlebar = false;
      };

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
        launchOrChange = pkgs.writeShellScript "launchOrChange" ''
                 #!/bin/sh
                    if swaymsg -t get_tree | grep $1
                    then  
                    swaymsg "workspace $3"
                    else
                    exec $2 & swaymsg "workspace $3"
          fi
        '';
      in {
        "${mod}+Return" = "exec ${terminal}";
        "${mod}+q" = "kill";
        "${mod}+Space" = "exec ${menu}";
        "${mod}+Shift+c" = ''
          exec clipman pick -t CUSTOM --tool-args="tofi --prompt-text=' Pick:'"
        '';
        "XF86MonBrightnessUp" = "light -A 10";

        "XF86MonBrightnessDown" = "light -U 10";
        "${mod}+s" = "exec flameshot gui";

        "${mod}+Ctrl+q" = "exec swaylock";
        "${mod}+Shift+e" = "exec tofi-powermenu";
        "${mod}+${left}" = "focus left";
        "${mod}+${down}" = "focus down";
        "${mod}+${up}" = "focus up";
        "${mod}+${right}" = "focus right";
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";
        "${mod}+Shift+${left}" = "move left";
        "${mod}+Shift+${down}" = "move down";
        "${mod}+Shift+${up}" = "move up";
        "${mod}+Shift+${right}" = "move right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";
        "${mod}+r" = "mode resize";
        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";

        "${mod}+Tab" = "exec $(swayr next-window current-workspace)";
        "${mod}+a" = "focus parent";
        "${mod}+Shift+t" = "focus mode_toggle";
        "${mod}+p" = "sticky toggle";
        "${mod}+Shift+f" = "fullscreen toggle";
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
        "${mod}+comma" = "layout stacking";
        "${mod}+period" = "layout tabbed";
        "${mod}+slash" = "layout toggle split";
        "${mod}+e" = "exec ${launchOrChange} pcmanfm pcmanfm 14";
        "${mod}+m" = "workspace number 19";
        "${mod}+d" =
          ''exec ${launchOrChange} emacs "emacsclient -c -a 'emacs'" 13'';
        "${mod}+f" = "exec ${launchOrChange} firefox firefox 11";
        "${mod}+t" =
          "exec ${launchOrChange} transmission-remote-gtk transmission-remote-gtk 20";

        "${mod}+Shift+q" = "exec swaylock";
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

        { command = "autotiling"; }
        { command = "keepassxc"; }

        {
          command = ''
            swaymsg for_window [app_id="org.keepassxc.KeePassXC"] move window to scratchpad'';
        }

        { command = "pcmanfm -d --no-desktop"; }
        { command = "wl-paste -t text --watch clipman store"; }

        { command = "transmission-remote-gtk"; }
        { command = "swayrd"; }
        { command = "emacsclient -a -c 'emacs'"; }

        {
          command =
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        }
        {
          command =
            "wl-paste -p -t text --watch clipman store -P --histpath='~/.local/state/clipman-primary.json'";
        }

      ];
      assigns = {
        "13" = [{ app_id = "emacs"; }];
        "11" = [{ app_id = "firefox"; }];
        "14" = [{ app_id = "pcmanfm"; }];
        "20" = [{ app_id = "transmission-remote-gtk"; }];
        "19" = [ { app_id = "mpv"; } { app_id = "ario"; } ];
      };
      workspaceOutputAssign = let
        output-1 = "Samsung Electric Company LS27A600U HCJW500005";
        output-2 = "LG Electronics LG ULTRAWIDE 0x0002A4C3";
      in [

        {
          output = output-1;
          workspace = "1";
        }

        {
          output = output-1;
          workspace = "2";
        }

        {
          output = output-1;
          workspace = "3";
        }

        {
          output = output-1;
          workspace = "4";
        }

        {
          output = output-1;
          workspace = "13";
        }

        {
          output = output-1;
          workspace = "14";
        }

        {
          output = output-2;
          workspace = "19";
        }

      ];
      floating.criteria = [{ title = "Picture-in-Picture"; }];
      window.commands = [
        {
          criteria = { app_id = "pavucontrol"; };
          command =
            "floating enable, sticky enable, move absolute position 60 5, resize set 630px  1070px;";
        }
        {
          command = "move to scratchpad";
          criteria = { title = "w+ KeePassXC"; };
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
        {
          # Open Zoom Meeting windows on a new workspace (a bit hacky)
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
