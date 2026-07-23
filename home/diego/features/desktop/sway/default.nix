{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;
  cursorName = config.stylix.cursor.name;
  cursorSize = toString config.stylix.cursor.size;

  # Package helper scripts
  launch-or-focus = pkgs.writeShellScriptBin "launch-or-focus" ''
    #!/usr/bin/env bash
    #
    # Launch an app on a specific workspace, or focus it if already running
    # Usage: launch-or-focus <app_id_or_class> <workspace> <launch_command>
    #

    APP_ID="$1"
    WORKSPACE="$2"
    shift 2
    LAUNCH_CMD="$@"

    # Check if window exists by app_id or class
    WINDOW_EXISTS=$(swaymsg -t get_tree | jq -r ".. | objects | select(.app_id == \"$APP_ID\" or .class == \"$APP_ID\") | .id" 2>/dev/null | head -1)

    if [ -n "$WINDOW_EXISTS" ]; then
        # Window exists - focus it (this also switches to its workspace)
        swaymsg "[con_id=\"$WINDOW_EXISTS\"] focus"
    else
        # Window doesn't exist - switch to workspace and launch
        swaymsg "workspace number $WORKSPACE"
        $LAUNCH_CMD &
    fi
  '';

  # Launcher for yazi on workspace 7 (file manager)
  # Switches to workspace 7; opens yazi if empty, or focuses existing
  yazi-launcher = pkgs.writeShellScriptBin "yazi-launcher" ''
    #!/usr/bin/env bash
    WORKSPACE="7"

    # Count leaf windows (app_id != null) on workspace 7
    HAS_WINDOWS=$(swaymsg -t get_tree | jq -r "
      [.. | objects |
        select(.type == \"workspace\" and .name == \"$WORKSPACE\") |
        .. | objects |
        select(.type == \"con\" and .app_id != null)
      ] | length
    " 2>/dev/null)

    if [ "$HAS_WINDOWS" -gt 0 ]; then
      swaymsg "workspace number $WORKSPACE"
    else
      # Switch to workspace 7, then tell Sway to exec alacritty -e yazi.
      # Using a single swaymsg command with ; ensures the workspace switch
      # completes before the app launches, so the window lands on workspace 7.
      swaymsg "workspace number $WORKSPACE; exec alacritty -e yazi"
    fi
  '';

  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    #!/usr/bin/env bash
    #
    # Power menu using rofi
    #

    OPTIONS=" Lock\n Logout\n Suspend\n Reboot\n Shutdown"

    CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Power")

    case "$CHOICE" in
        *"Lock")
            swaylock -f
            ;;
        *"Logout")
            swaymsg exit
            ;;
        *"Suspend")
            swaylock -f && systemctl suspend
            ;;
        *"Reboot")
            systemctl reboot
            ;;
        *"Shutdown")
            systemctl poweroff
            ;;
    esac
  '';

  web-search = pkgs.writeShellScriptBin "web-search" ''
    #!/usr/bin/env bash
    #
    # Web search using rofi
    #

    ENGINES=(
        "Google|https://www.google.com/search?q="
        "GitHub|https://github.com/search?q="
        "YouTube|https://www.youtube.com/results?search_query="
        "Wikipedia|https://en.wikipedia.org/wiki/Special:Search?search="
        "StackOverflow|https://stackoverflow.com/search?q="
        "Reddit|https://www.reddit.com/search?q="
        "MDN|https://developer.mozilla.org/en-US/search?q="
        "NixOS Packages|https://search.nixos.org/packages?query="
    )

    LIST=$(printf '%s\n' "''${ENGINES[@]%%|*}")
    ENGINE=$(echo "$LIST" | rofi -dmenu -p "Search")
    [ -z "$ENGINE" ] && exit 0

    URL=""
    for entry in "''${ENGINES[@]}"; do
        NAME="''${entry%%|*}"
        if [ "$ENGINE" = "$NAME" ]; then
            URL="''${entry#*|}"
            break
        fi
    done
    [ -z "$URL" ] && exit 0

    QUERY=$(echo "" | rofi -dmenu -p "$ENGINE")
    [ -z "$QUERY" ] && exit 0

    xdg-open "$URL$QUERY"
  '';

  # Script to manage virtual output for phone streaming via Sunshine
  sunshine-stream = pkgs.writeShellScriptBin "sunshine-stream" ''
    #!/usr/bin/env bash
    #
    # Manage virtual output for Sunshine phone streaming
    # Resolution is set via swaymsg directly (kanshi doesn't handle HEADLESS modes)
    #
    # Usage:
    #   sunshine-stream start [WxH]   - start stream at resolution (default: 1080x2436)
    #   sunshine-stream start 1290x2796
    #   sunshine-stream start landscape
    #   sunshine-stream stop
    #   sunshine-stream toggle [WxH]
    #   sunshine-stream status
    #

    ACTION="''${1:-toggle}"
    RES_ARG="''${2:-}"
    DEFAULT_RES="1080x2436"

    has_headless() {
      swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -e '.[] | select(.name == "HEADLESS-1")' > /dev/null 2>&1
    }

    start_stream() {
      local RES
      case "$RES_ARG" in
        landscape|horizontal)
          RES="2796x1290"
          ;;
        1290x2796|1290)
          RES="1290x2796"
          ;;
        1080x2436|1080)
          RES="1080x2436"
          ;;
        "")
          RES="$DEFAULT_RES"
          ;;
        *)
          RES="$RES_ARG"
          ;;
      esac

      if has_headless; then
        notify-send "Sunshine" "Phone stream already active"
        exit 0
      fi

      # Create virtual output
      swaymsg create_output HEADLESS
      sleep 0.5

      # Set custom resolution (HEADLESS outputs have no built-in modes)
      swaymsg output HEADLESS-1 resolution "$RES"

      # Move workspace 9 to virtual output and switch to it
      swaymsg 'workspace number 9; move workspace to output HEADLESS-1'

      notify-send "Sunshine" "Phone stream ready on workspace 9 ($RES)"
    }

    case "$ACTION" in
      start)
        start_stream
        ;;
      stop)
        if ! has_headless; then
          notify-send "Sunshine" "Phone stream not active"
          exit 0
        fi
        # Move workspace 9 back to primary
        swaymsg 'workspace number 9; move workspace to output eDP-1' || true
        # Switch back to single mode
        kanshictl switch single || true
        # Destroy virtual output
        swaymsg output HEADLESS-1 unplug 2>/dev/null || true
        notify-send "Sunshine" "Phone stream stopped"
        ;;
      toggle)
        if has_headless; then
          exec "$0" stop
        else
          exec "$0" start "$RES_ARG"
        fi
        ;;
      status)
        if has_headless; then
          echo "Phone stream: ACTIVE"
          swaymsg -t get_outputs | ${pkgs.jq}/bin/jq '.[] | select(.name == "HEADLESS-1")'
        else
          echo "Phone stream: INACTIVE"
        fi
        ;;
      *)
        echo "Usage: sunshine-stream [start [WxH]|stop|toggle [WxH]|status]"
        echo ""
        echo "Examples:"
        echo "  sunshine-stream start         1080x2436 (portrait, default)"
        echo "  sunshine-stream start 1290    1290x2796 (large phone portrait)"
        echo "  sunshine-stream start landscape 2796x1290 (landscape)"
        exit 1
        ;;
    esac
  '';

  # Script to mirror and control Android device via scrcpy
  scrcpy-stream = pkgs.writeShellScriptBin "scrcpy-stream" ''
    #!/usr/bin/env bash
    #
    # Mirror and control an Android device via scrcpy on a dedicated workspace.
    #
    # Usage:
    #   scrcpy-stream toggle               - toggle mirroring (default)
    #   scrcpy-stream start                 - start mirroring on workspace 10
    #   scrcpy-stream stop                  - stop mirroring
    #   scrcpy-stream status                - show ADB device status
    #   scrcpy-stream list                  - list connected ADB devices
    #
    # Wireless ADB (no USB cable needed after setup):
    #   1. Connect phone via USB, then run:  scrcpy-stream wireless
    #   2. Disconnect USB, note the IP from: scrcpy-stream ip
    #   3. Connect over WiFi:                scrcpy-stream connect <ip>
    #   Then use scrcpy-stream toggle as usual.
    #
    #   scrcpy-stream wireless [port]  - switch USB device to TCP mode (default port 5555)
    #   scrcpy-stream ip               - show IP address of connected device
    #   scrcpy-stream connect <ip>     - connect to a wireless device
    #   scrcpy-stream disconnect [id]  - disconnect wireless device
    #   scrcpy-stream pair <host> <code> - pair with Android 11+ wireless debugging
    #
    # Requirements: scrcpy, android-tools (adb)

    ACTION="''${1:-toggle}"

    ADB=${pkgs.android-tools}/bin/adb
    SCRCPY=${pkgs.scrcpy}/bin/scrcpy

    list_devices() {
      "$ADB" devices -l 2>/dev/null
    }

    count_devices() {
      # adb devices plain-text output:
      #   List of devices attached
      #   R58NA04G8YA    device product:... model:... device:...
      # Count lines after the header that have a serial (non-empty, not "attached")
      "$ADB" devices 2>/dev/null | awk 'NR>1 && NF>0 && !/attached/ {count++} END {print count+0}'
    }

    has_usb_device() {
      # Only count USB-connected devices (serial has no ":" like IP:port would)
      "$ADB" devices -l 2>/dev/null | awk 'NR>1 && NF>0 && !/attached/ && $1 !~ /:/ {count++} END {exit count==0}'
    }

    has_device() {
      [ "$(count_devices)" -gt 0 ] 2>/dev/null
    }

    # Check if scrcpy is running (match the binary name, not the helper script)
    is_running() {
      pgrep -x scrcpy >/dev/null 2>&1
    }

    get_scrcpy_pid() {
      pgrep -x scrcpy 2>/dev/null | head -1
    }

    get_device_ip() {
      "$ADB" shell ip -4 addr show wlan0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -1
    }

    start_mirror() {
      if is_running; then
        notify-send "scrcpy" "Android mirror already active (PID $(get_scrcpy_pid))"
        # Focus the scrcpy window
        swaymsg "[app_id=\"scrcpy\"] focus" 2>/dev/null || true
        exit 0
      fi

      # Ensure ADB server is running
      "$ADB" start-server 2>/dev/null

      # Check for connected device
      if ! has_device; then
        notify-send -u critical "scrcpy" "No Android device detected via ADB\nConnect your phone or run 'scrcpy-stream connect <ip>' for wireless."
        exit 1
      fi

      # Switch to workspace 10 before launching
      swaymsg 'workspace number 10'

      # Launch scrcpy with optimal defaults:
      #   --turn-screen-off : conserve phone battery
      #   --max-size 1080   : cap resolution for performance
      #   --stay-awake      : keep phone awake while connected
      #   --no-audio        : avoid audio capture issues on some devices
      #   --window-title    : identify the window in sway
      $SCRCPY \
        --turn-screen-off \
        --max-size 1080 \
        --stay-awake \
        --no-audio \
        --window-title "Android (scrcpy)" &

      # Wait for window to appear then ensure it's on workspace 10
      sleep 1
      swaymsg "[title=\"Android (scrcpy)\"] move workspace number 10" 2>/dev/null || true

      notify-send "scrcpy" "Android mirror started on workspace 10"
    }

    stop_mirror() {
      if ! is_running; then
        notify-send "scrcpy" "Android mirror not active"
        exit 0
      fi

      local PID
      PID=$(get_scrcpy_pid)
      kill "$PID" 2>/dev/null
      notify-send "scrcpy" "Android mirror stopped"
    }

    enable_wireless() {
      local PORT="''${2:-5555}"

      # First ensure the adb server is running
      "$ADB" start-server 2>/dev/null

      if ! has_usb_device; then
        echo "No USB-connected Android device found."
        echo "Connect your phone via USB first (with USB debugging enabled)."
        exit 1
      fi

      echo "Switching device to TCP mode on port $PORT ..."
      if "$ADB" tcpip "$PORT"; then
        echo ""
        echo "  ✓ Wireless ADB enabled on port $PORT"
        echo "  Now disconnect the USB cable and connect over WiFi:"
        echo ""
        echo "    scrcpy-stream ip        # find the device IP"
        echo "    scrcpy-stream connect <ip>  # connect wirelessly"
        echo "    scrcpy-stream toggle    # start mirroring"
      else
        echo "Failed to enable wireless mode."
        exit 1
      fi
    }

    show_ip() {
      if ! has_device; then
        echo "No device connected. Connect via USB or connect wirelessly first."
        exit 1
      fi

      local IP
      IP=$(get_device_ip)
      if [ -n "$IP" ]; then
        echo "Device IP: $IP"
        echo ""
        echo "Connect wirelessly:  scrcpy-stream connect $IP"
      else
        echo "Could not determine device IP (wlan0 may be down)."
        echo "Check the device's WiFi status."
        "$ADB" shell ip addr show wlan0 2>/dev/null || echo "(failed to query network interfaces)"
      fi
    }

    connect_wireless() {
      local HOST="''${2:-}"
      if [ -z "$HOST" ]; then
        echo "Usage: scrcpy-stream connect <device-ip>[:port]"
        echo ""
        echo "Examples:"
        echo "  scrcpy-stream connect 192.168.1.42"
        echo "  scrcpy-stream connect 192.168.1.42:5555"
        exit 1
      fi

      "$ADB" start-server 2>/dev/null
      echo "Connecting to $HOST ..."
      "$ADB" connect "$HOST"
    }

    disconnect_wireless() {
      local HOST="''${2:-}"
      if [ -n "$HOST" ]; then
        "$ADB" disconnect "$HOST"
      else
        # Disconnect all wireless devices
        "$ADB" disconnect
      fi
    }

    pair_device() {
      local HOST="''${2:-}"
      local CODE="''${3:-}"
      if [ -z "$HOST" ] || [ -z "$CODE" ]; then
        echo "Usage: scrcpy-stream pair <host:port> <pairing-code>"
        echo ""
        echo "For Android 11+ Wireless Debugging:"
        echo "  1. Enable Developer options on your phone"
        echo "  2. Enable 'Wireless debugging'"
        echo "  3. Tap 'Pair device with pairing code'"
        echo "  4. Run: scrcpy-stream pair <ip>:<port> <code>"
        echo ""
        echo "After pairing, connect with: scrcpy-stream connect <ip>:<port>"
        exit 1
      fi

      echo "Pairing with $HOST ..."
      "$ADB" pair "$HOST" "$CODE"
    }

    case "$ACTION" in
      start)
        start_mirror
        ;;
      stop)
        stop_mirror
        ;;
      toggle)
        if is_running; then
          stop_mirror
        else
          start_mirror
        fi
        ;;
      status)
        if is_running; then
          echo "Android mirror: RUNNING (PID $(get_scrcpy_pid))"
        else
          echo "Android mirror: STOPPED"
        fi
        echo ""
        echo "Connected ADB devices:"
        "$ADB" devices -l 2>/dev/null || echo "  (none)"
        ;;
      list)
        list_devices
        ;;
      wireless|tcpip)
        enable_wireless "$@"
        ;;
      ip|ipaddr|address)
        show_ip
        ;;
      connect)
        connect_wireless "$@"
        ;;
      disconnect)
        disconnect_wireless "$@"
        ;;
      pair)
        pair_device "$@"
        ;;
      *)
        echo "Usage: scrcpy-stream {start|stop|toggle|status|list|wireless|ip|connect|disconnect|pair}"
        echo ""
        echo "Mirror / control an Android device via scrcpy."
        echo ""
        echo "Wired:  Connect USB → toggle starts mirroring on workspace 10"
        echo ""
        echo "Wireless setup (first time only):"
        echo "  1. Connect USB → scrcpy-stream wireless"
        echo "  2. Disconnect USB → scrcpy-stream ip → scrcpy-stream connect <ip>"
        echo "  3. scrcpy-stream toggle"
        echo ""
        echo "Android 11+ Wireless Debugging (alternative):"
        echo "  1. Enable 'Wireless debugging' in Developer options"
        echo "  2. Tap 'Pair device with pairing code'"
        echo "  3. scrcpy-stream pair <host:port> <code>"
        echo "  4. scrcpy-stream connect <host:port>"
        exit 1
        ;;
    esac
  '';

  volume-notify = pkgs.writeShellScriptBin "volume-notify" ''
    #!/usr/bin/env bash
    case "''${1:-}" in
      up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
      down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
      mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      mic)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        MIC=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
        if echo "$MIC" | grep -q MUTED; then
          notify-send -t 1500 -c volume \
            -h string:x-canonical-private-synchronous:mic \
            "Microphone" "Muted"
        else
          notify-send -t 1500 -c volume \
            -h string:x-canonical-private-synchronous:mic \
            "Microphone" "Unmuted"
        fi
        exit 0
        ;;
    esac
    INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    VOL=$(echo "$INFO" | awk '{print int($2 * 100)}')
    if echo "$INFO" | grep -q MUTED; then
      notify-send -t 1500 -c volume \
        -h string:x-canonical-private-synchronous:volume \
        -h int:value:0 \
        "Volume" "Muted"
    else
      notify-send -t 1500 -c volume \
        -h string:x-canonical-private-synchronous:volume \
        -h int:value:"$VOL" \
        "Volume" "$VOL%"
    fi
  '';

  brightness-notify = pkgs.writeShellScriptBin "brightness-notify" ''
    #!/usr/bin/env bash
    case "''${1:-}" in
      up)   brillo -A 5 ;;
      down) brillo -U 5 ;;
    esac
    BRI=$(brillo | awk '{print int($1 + 0.5)}')
    notify-send -t 1500 -c brightness \
      -h string:x-canonical-private-synchronous:brightness \
      -h int:value:"$BRI" \
      "Brightness" "$BRI%"
  '';

  swap-workspace-output = pkgs.writeShellScriptBin "swap-workspace-output" ''
        #!/usr/bin/env bash
        set -euo pipefail

        DIRECTION="''${1:-}"
        case "$DIRECTION" in
          left|right) ;;
          *)
            echo "Usage: swap-workspace-output left|right" >&2
            exit 1
            ;;
        esac

        # Resolve the output and workspace the user is currently on.
        CUR_OUT=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        CUR_WS=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .current_workspace // empty')

        [ -n "$CUR_WS" ] || exit 0

        # Resolve the adjacent output in the requested direction by its name.
        # `focus output left|right` is cyclic, so capture the resolved name and
        # always operate on explicit output names afterwards (deterministic on 2+
        # monitors, no reliance on directional move semantics).
        swaymsg focus output "$DIRECTION" >/dev/null
        ADJ_OUT=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        ADJ_WS=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .current_workspace // empty')

        # Single-monitor (or no distinct adjacent output): focus wrapped back to us.
        if [ "$ADJ_OUT" = "$CUR_OUT" ] || [ -z "$ADJ_WS" ]; then
          swaymsg focus output "$CUR_OUT" >/dev/null
          swaymsg workspace "$CUR_WS" >/dev/null
          exit 0
        fi

        # Swap the two workspaces by explicit output name.
        # ADJ_WS is currently focused on ADJ_OUT; send it to CUR_OUT.
        swaymsg move workspace to output "$CUR_OUT" >/dev/null
        # Bring CUR_WS into focus on CUR_OUT, then send it to ADJ_OUT.
        swaymsg focus output "$CUR_OUT" >/dev/null
        swaymsg workspace "$CUR_WS" >/dev/null
        swaymsg move workspace to output "$ADJ_OUT" >/dev/null

        # Stay on the physical output the user started on (CUR_OUT), now showing ADJ_WS.
        swaymsg focus output "$CUR_OUT" >/dev/null
        swaymsg workspace "$ADJ_WS" >/dev/null

        # Move the pointer to the center of CUR_OUT so it follows the user's output.
        eval "$(${pkgs.jq}/bin/jq -r --arg out "$CUR_OUT" '
          .[] | select(.name == $out) |
          "CURSOR_X=\(.rect.x + .rect.width / 2 | floor)
    CURSOR_Y=\(.rect.y + .rect.height / 2 | floor)"
        ' < <(swaymsg -t get_outputs))"
        swaymsg seat seat0 cursor set "$CURSOR_X" "$CURSOR_Y" >/dev/null
  '';
in
{
  imports = [
    ./waybar.nix
    ./kanshi.nix
    ./mako.nix
    ./swaylock.nix
    ./rofi.nix
    ./bluetooth.nix
  ];

  # Cliphist clipboard manager (systemd service)
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # Sway packages and helper scripts
  home.packages = with pkgs; [
    wdisplays
    j
    nice-dcv-client
    swayr
    jq
    autotiling-rs
    polkit_gnome
    rofi
    # Screenshot tools
    swappy
    grim
    slurp
    wl-clipboard
    xdg-utils
    wifitui
    # Helper scripts
    launch-or-focus
    yazi-launcher
    power-menu
    web-search
    sunshine-stream
    swap-workspace-output
    scrcpy-stream
    volume-notify
    brightness-notify
    # Android mirroring & control
    scrcpy
  ];

  xdg.configFile."environment.d/xdg.conf".text = ''
    XDG_SESSION_TYPE=wayland
    XDG_CURRENT_DESKTOP=sway
  '';

  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.sway;
    checkConfig = false;

    config = {
      modifier = "Mod4";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      terminal = "alacritty";
      menu = "rofi -show drun";

      bars = [ ];

      fonts = {
        names = [ "Fantasque Sans Mono" ];
        size = lib.mkForce 17.0;
      };

      window = {
        border = 4;
        hideEdgeBorders = "none";
      };

      floating = {
        border = 4;
        modifier = "Mod4";
      };

      gaps = {
        inner = 8;
        outer = 4;
        smartGaps = "on";
        smartBorders = "on";
      };

      colors = lib.mkForce {
        focused = {
          border = "#${colors.base0D}";
          background = "#${colors.base0D}";
          text = "#${colors.base00}";
          indicator = "#${colors.base04}";
          childBorder = "#${colors.base0D}";
        };
        focusedInactive = {
          border = "#${colors.base02}";
          background = "#${colors.base0D}";
          text = "#${colors.base00}";
          indicator = "#${colors.base03}";
          childBorder = "#${colors.base01}";
        };
        unfocused = {
          border = "#${colors.base01}";
          background = "#${colors.base01}";
          text = "#${colors.base06}";
          indicator = "#${colors.base01}";
          childBorder = "#${colors.base01}";
        };
        urgent = {
          border = "#${colors.base08}";
          background = "#${colors.base01}";
          text = "#${colors.base08}";
          indicator = "#${colors.base08}";
          childBorder = "#${colors.base08}";
        };
        placeholder = {
          border = "#${colors.base01}";
          background = "#${colors.base01}";
          text = "#${colors.base03}";
          indicator = "#${colors.base01}";
          childBorder = "#${colors.base01}";
        };
        background = "#${colors.base01}";
      };

      assigns = {
        "5" = [
          { app_id = "firefox"; }
        ];
        "6" = [
          { app_id = "thunderbird"; }
        ];
        # yazi (launched via yazi-launcher script) is the only app on workspace 7
        "8" = [
          { app_id = "obsidian"; }
        ];
      };

      window.commands = [
        {
          criteria = {
            app_id = "swappy";
          };
          command = "floating enable";
        }
        # Inhibit idle while Firefox is focused so swayidle doesn't fire the lock
        # timer during screen shares (the XDG Inhibit portal isn't supported by
        # xdg-desktop-portal-wlr, so apps can't prevent lock via the portal).
        {
          criteria.app_id = "firefox-devedition";
          command = "inhibit_idle focus";
        }
        {
          criteria.app_id = "firefox";
          command = "inhibit_idle focus";
        }
      ];

      input = {
        "type:keyboard" = {
          xkb_layout = "us,es";
          xkb_options = "caps:ctrl_modifier,grp:alt_space_toggle";
        };
        "type:touchpad" = {
          natural_scroll = "enabled";
          tap = "enabled";
          dwt = "enabled";
        };
      };

      seat = {
        seat0 = {
          xcursor_theme = "${cursorName} ${cursorSize}";
        };
      };

      bindswitches = {
        "lid:on" = {
          action = "exec swaylock -f && systemctl suspend";
          reload = true;
          locked = true;
        };
      };

      startup = [
        # Idle daemon: lock after 5min, display off after 10min
        {
          command = "swayidle -w timeout 300 'swaylock -f' timeout 600 'swaymsg \"output * power off\"' resume 'swaymsg \"output * power on\"' before-sleep 'swaylock -f'";
        }

        # Cursor theme for XWayland apps
        {
          command = "export XCURSOR_THEME=${cursorName}";
          always = true;
        }
        {
          command = "export XCURSOR_SIZE=${cursorSize}";
          always = true;
        }

        # Polkit authentication agent
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }

        # Swayr daemon for window tracking
        { command = "swayr daemon"; }

        # Autotiling for automatic split orientation
        { command = "autotiling-rs"; }

        # DBus environment
        {
          command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XCURSOR_THEME XCURSOR_SIZE";
        }
        {
          command = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE";
        }
        {
          command = "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP";
        }
        {
          command = "hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP";
        }

        # GTK cursor theme
        {
          command = "gsettings set org.gnome.desktop.interface cursor-theme '${cursorName}'";
          always = true;
        }
        {
          command = "gsettings set org.gnome.desktop.interface cursor-size ${cursorSize}";
          always = true;
        }
      ];

      keybindings = {
        # Basics
        "Mod4+Return" = "exec alacritty";
        "Mod4+w" = "kill";

        "Mod4+p" = "floating enable, sticky enable";
        "Mod4+space" = "exec rofi -show drun";
        "Mod4+Shift+c" = "reload";
        "Mod4+Shift+e" = "exec power-menu";
        "Mod4+Escape" = "exec swaylock -f";

        # Brightness controls
        "XF86MonBrightnessUp" = "exec brightness-notify up";
        "XF86MonBrightnessDown" = "exec brightness-notify down";

        # Volume controls
        "XF86AudioRaiseVolume" = "exec volume-notify up";
        "XF86AudioLowerVolume" = "exec volume-notify down";
        "XF86AudioMute" = "exec volume-notify mute";
        "XF86AudioMicMute" = "exec volume-notify mic";

        # Screenshots
        "Mod4+Shift+s" = "exec grim -g \"$(slurp)\" - | swappy -f -";
        "Print" = "exec grim - | wl-copy";
        "Mod4+Shift+a" = "exec grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png";

        # Clipboard history
        "Mod4+c" = "exec cliphist list | rofi -dmenu | cliphist decode | wl-copy";

        # Web search
        "Mod4+s" = "exec web-search";

        # Focus movement
        "Mod4+h" = "focus left";
        "Mod4+j" = "focus down";
        "Mod4+k" = "focus up";
        "Mod4+l" = "focus right";
        "Mod4+Left" = "focus left";
        "Mod4+Down" = "focus down";
        "Mod4+Up" = "focus up";
        "Mod4+Right" = "focus right";

        # Move focused window
        "Mod4+Shift+h" = "move left";
        "Mod4+Shift+j" = "move down";
        "Mod4+Shift+k" = "move up";
        "Mod4+Shift+l" = "move right";
        "Mod4+Shift+Left" = "move left";
        "Mod4+Shift+Down" = "move down";
        "Mod4+Shift+Up" = "move up";
        "Mod4+Shift+Right" = "move right";

        # Workspace switching
        "Mod4+1" = "workspace number 1";
        "Mod4+2" = "workspace number 2";
        "Mod4+3" = "workspace number 3";
        "Mod4+4" = "workspace number 4";
        "Mod4+5" = "workspace number 5";
        "Mod4+6" = "workspace number 6";
        "Mod4+7" = "workspace number 7";
        "Mod4+8" = "workspace number 8";
        "Mod4+9" = "workspace number 9";
        "Mod4+0" = "workspace number 10";

        # Horizontal workspace switching
        "Mod4+Tab" = "workspace next";
        "Mod4+Shift+Tab" = "workspace prev";

        # Move container to workspace
        "Mod4+Shift+1" = "move container to workspace number 1";
        "Mod4+Shift+2" = "move container to workspace number 2";
        "Mod4+Shift+3" = "move container to workspace number 3";
        "Mod4+Shift+4" = "move container to workspace number 4";
        "Mod4+Shift+5" = "move container to workspace number 5";
        "Mod4+Shift+6" = "move container to workspace number 6";
        "Mod4+Shift+7" = "move container to workspace number 7";
        "Mod4+Shift+8" = "move container to workspace number 8";
        "Mod4+Shift+9" = "move container to workspace number 9";
        "Mod4+Shift+0" = "move container to workspace number 10";

        # Layout
        "Mod4+b" = "splith";
        "Mod4+v" = "splitv";
        "Mod4+u" = "layout stacking";
        "Mod4+i" = "layout tabbed";
        "Mod4+o" = "layout toggle split";
        "Mod4+Shift+f" = "fullscreen";
        "Mod4+Shift+space" = "floating toggle";
        "Mod4+a" = "focus parent";

        # Scratchpad
        "Mod4+Shift+minus" = "move scratchpad";
        "Mod4+minus" = "scratchpad show";

        # Launch-or-focus shortcuts
        "Mod4+f" = "exec launch-or-focus firefox-devedition 5 firefox-devedition";
        "Mod4+g" = "exec launch-or-focus thunderbird 6 thunderbird";

        "Mod4+d" = "exec cursor";
        "Mod4+e" = "exec yazi-launcher";
        "Mod4+n" = "exec launch-or-focus obsidian 8 obsidian";

        # Display mode switching (kanshi)
        "Mod4+Shift+d" = "exec display-mode-selector";
        "Mod4+Ctrl+1" = "exec kanshi-switch single";
        "Mod4+Ctrl+2" = "exec kanshi-switch docked";
        "Mod4+Ctrl+3" = "exec kanshi-switch triple";

        # Sunshine iPhone streaming (Moonlight/Sunshine)
        "Mod4+Shift+p" = "exec sunshine-stream toggle"; # Toggle phone stream mode
        "Mod4+Ctrl+p" =
          "exec sunshine-stream status && notify-send 'Sunshine' \"$(sunshine-stream status)\""; # Show status

        # Android mirroring & control (scrcpy)
        "Mod4+Shift+o" = "exec scrcpy-stream toggle"; # Toggle Android mirror
        "Mod4+Ctrl+o" = "exec scrcpy-stream status && notify-send 'scrcpy' \"$(scrcpy-stream status)\""; # Show status

        # Swap workspaces between outputs
        "Mod4+Ctrl+Left" = "exec swap-workspace-output left";
        "Mod4+Ctrl+Right" = "exec swap-workspace-output right";

        # Gap resizing
        "Mod4+Ctrl+equal" = "gaps inner current plus 4";
        "Mod4+Ctrl+minus" = "gaps inner current minus 4";
        "Mod4+Ctrl+Shift+equal" = "gaps outer current plus 4";
        "Mod4+Ctrl+Shift+minus" = "gaps outer current minus 4";
        "Mod4+Ctrl+0" = "gaps inner current set 0, gaps outer current set 0";
        "Mod4+Ctrl+9" = "gaps inner current set 8, gaps outer current set 4";

        # Resize mode
        "Mod4+r" = "mode resize";
      };

      modes = {
        resize = {
          h = "resize shrink width 10px";
          j = "resize grow height 10px";
          k = "resize shrink height 10px";
          l = "resize grow width 10px";
          Left = "resize shrink width 10px";
          Down = "resize grow height 10px";
          Up = "resize shrink height 10px";
          Right = "resize grow width 10px";
          Return = "mode default";
          Escape = "mode default";
        };
      };
    };

    extraConfig = ''
      default_border pixel 2

      titlebar_border_thickness 0
      titlebar_padding 8 4

      output * bg   #${colors.base00} solid_color

      bindgesture swipe:4:left workspace prev
      bindgesture swipe:4:right workspace next

      include /etc/sway/config-vars.d/*
      include /etc/sway/config.d/*
    '';
  };
}
