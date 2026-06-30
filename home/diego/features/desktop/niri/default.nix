{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  cursorName = config.stylix.cursor.name;
  cursorSize = toString config.stylix.cursor.size;
in
{
  imports = [ ./dms.nix ];

  programs.niri.package = pkgs.niri;

  # Stylix enabled via inputs.niri.homeModules.stylix (defaults to true)
  # Bar, launcher, notifications, lock, idle, clipboard, polkit are all
  # provided by DankMaterialShell (see ./dms.nix).

  home.packages = with pkgs; [
    jq
    grim
    slurp
    wl-clipboard
    swaybg
    awww
  ];

  # XDG desktop portal config for niri
  xdg.configFile."environment.d/xdg.conf".text = ''
    XDG_SESSION_TYPE=wayland
    XDG_CURRENT_DESKTOP=niri
  '';

  # Niri declarative configuration (attribute set → validated KDL)
  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    hotkey-overlay = {
      skip-at-startup = false;
      hide-not-bound = false;
    };
    cursor = {
      theme = cursorName;
      size = lib.toInt cursorSize;
      hide-after-inactive-ms = 3000;
    };

    input = {
      keyboard = {
        xkb = {
          layout = "us,es";
          options = "caps:ctrl_modifier,grp:alt_space_toggle";
        };
        track-layout = "global";
      };
      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = true;
        scroll-method = "two-finger";
        click-method = "clickfinger";
      };
      focus-follows-mouse.enable = false;
      workspace-auto-back-and-forth = true;
    };

    outputs."eDP-1" = {
      scale = 1.0;
      background-color = "#${colors.base00}";
    };

    layout = {
      gaps = 8;
      border.enable = true;
      border.width = 2;
      focus-ring.enable = true;
      focus-ring.width = 2;
    };

    # Window rules for workspace assignment + rounded corners
    window-rules = [
      {
        matches = [ { app-id = "^firefox$"; } ];
        open-on-workspace = "5";
      }
      {
        matches = [ { app-id = "^thunderbird$"; } ];
        open-on-workspace = "6";
      }
      {
        matches = [ { app-id = "^obsidian$"; } ];
        open-on-workspace = "8";
      }
      # Round corners for all windows
      {
        geometry-corner-radius = {
          top-left = 8.0;
          top-right = 8.0;
          bottom-right = 8.0;
          bottom-left = 8.0;
        };
        clip-to-geometry = true;
      }
    ];

    # Show the awww wallpaper inside the overview backdrop too.
    layer-rules = [
      {
        matches = [ { namespace = "^awww-daemon$"; } ];
        place-within-backdrop = true;
      }
    ];

    spawn-at-startup = [
      # Wallpaper: animated daemon + initial NASA ISS wallpaper.
      # (Bar/launcher/notifications/lock/idle/polkit are spawned by DMS.)
      { argv = [ "awww-daemon" ]; }
      { argv = [ "nasa-apod-wallpaper" ]; }
    ];

    environment = {
      NIXOS_OZONE_WL = "1";
      XCURSOR_THEME = cursorName;
      XCURSOR_SIZE = cursorSize;
    };

    binds = {
      # Terminal (launcher, lock, power menu, clipboard provided by DMS)
      "Mod+Return".action.spawn = "alacritty";

      # Close window
      "Mod+W".action.close-window = { };

      # Focus movement (vim-style for columns + arrows for workspace switching)
      "Mod+H".action.focus-column-left = { };
      "Mod+J".action.focus-window-down = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+Up".action.focus-workspace-up = { };
      "Mod+Down".action.focus-workspace-down = { };

      # Move windows (horizontally = columns via vim, across workspaces via arrows)
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+J".action.move-window-down = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+Up".action.move-window-to-workspace-up = { };
      "Mod+Shift+Down".action.move-window-to-workspace-down = { };

      # Toggle floating
      "Mod+Shift+Space".action.toggle-window-floating = { };

      # Fullscreen
      "Mod+Shift+F".action.fullscreen-window = { };

      # Workspace switching
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+0".action.focus-workspace = 10;

      # Move windows to workspace
      "Mod+Shift+1".action.move-window-to-workspace = 1;
      "Mod+Shift+2".action.move-window-to-workspace = 2;
      "Mod+Shift+3".action.move-window-to-workspace = 3;
      "Mod+Shift+4".action.move-window-to-workspace = 4;
      "Mod+Shift+5".action.move-window-to-workspace = 5;
      "Mod+Shift+6".action.move-window-to-workspace = 6;
      "Mod+Shift+7".action.move-window-to-workspace = 7;
      "Mod+Shift+8".action.move-window-to-workspace = 8;
      "Mod+Shift+9".action.move-window-to-workspace = 9;
      "Mod+Shift+0".action.move-window-to-workspace = 10;

      # App shortcuts
      "Mod+F".action.spawn = "firefox";
      "Mod+G".action.spawn = "thunderbird";
      "Mod+O".action.spawn = "obsidian";

      # Manual wallpaper refresh
      "Mod+Shift+W".action.spawn = "nasa-apod-wallpaper";

      # Screenshots
      "Print".action.screenshot = { };
      "Mod+Shift+S".action.screenshot-screen = { };
      "Mod+Shift+A".action.screenshot-window = { };

      # Hotkey overlay
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };
      "Mod+T".action.toggle-column-tabbed-display = { };
      "Mod+Shift+T".action.consume-or-expel-window-left = { };

      # Column width adjustments (bracket keys match left/right direction)
      "Mod+BracketLeft".action.set-column-width = "-5%";
      "Mod+BracketRight".action.set-column-width = "+5%";

      # Window height adjustments
      "Mod+Minus".action.set-window-height = "-10%";
      "Mod+Equal".action.set-window-height = "+10%";
      "Mod+Shift+Minus".action.reset-window-height = { };

      # Preset column width cycling
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Shift+R".action.switch-preset-column-width-back = { };

      # Centering and maximizing
      "Mod+Shift+C".action.center-column = { };
      "Mod+Ctrl+C".action.center-window = { };
      "Mod+Shift+M".action.maximize-column = { };
      "Mod+Shift+Equal".action.expand-column-to-available-width = { };

      # Workspace back-and-forth / overview
      "Mod+Tab".action.focus-workspace-previous = { };
      "Mod+Shift+Tab".action.toggle-overview = { };

      # Scroll on background to navigate workspaces/columns
      "Mod+WheelScrollDown" = {
        action.focus-workspace-down = { };
        "cooldown-ms" = 150;
      };
      "Mod+WheelScrollUp" = {
        action.focus-workspace-up = { };
        "cooldown-ms" = 150;
      };
      "Mod+WheelScrollLeft" = {
        action.focus-column-left = { };
        "cooldown-ms" = 150;
      };
      "Mod+WheelScrollRight" = {
        action.focus-column-right = { };
        "cooldown-ms" = 150;
      };

      # Overview toggle via scroll (both directions, no cooldown needed)
      "Mod+Shift+WheelScrollUp".action.toggle-overview = { };
      "Mod+Shift+WheelScrollDown".action.toggle-overview = { };

    };
  };
}
