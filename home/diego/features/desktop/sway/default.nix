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
  workspaces = (import ./workspaces.nix { inherit lib; }).registry;

  wsTarget = n: if workspaces.${n}.nameless or false then "${n}:" else n;

  launch-or-focus = pkgs.writeShellScriptBin "launch-or-focus" ''
    #!/usr/bin/env bash

    APP_ID="$1"
    WORKSPACE="$2"
    shift 2
    LAUNCH_CMD="$@"

    WINDOW_EXISTS=$(swaymsg -t get_tree | jq -r ".. | objects | select(.app_id == \"$APP_ID\" or .class == \"$APP_ID\") | .id" 2>/dev/null | head -1)

    if [ -n "$WINDOW_EXISTS" ]; then
        swaymsg "[con_id=\"$WINDOW_EXISTS\"] focus"
    else
        swaymsg "workspace number $WORKSPACE"
        $LAUNCH_CMD &
    fi
  '';

  yazi-launcher = pkgs.writeShellScriptBin "yazi-launcher" ''
    #!/usr/bin/env bash
    WORKSPACE="7"

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
      swaymsg "workspace number $WORKSPACE; exec alacritty -e yazi"
    fi
  '';

  helix-launcher = pkgs.writeShellScriptBin "helix-launcher" ''
    #!/usr/bin/env bash
    WORKSPACE="9"

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
      swaymsg "workspace number $WORKSPACE; exec alacritty -e hx"
    fi
  '';

  opencode-launcher = pkgs.writeShellScriptBin "opencode-launcher" ''
    #!/usr/bin/env bash
    WORKSPACE="10"

    DAILY_PROMPT="Read today's daily note, the active projects, and anything due \
    or overdue in the vault, then answer one question: what should I focus on today? \
    Reply with a single markdown list, highest priority first, at most 7 items. \
    One line per item: the task, then a short why in parentheses. No preamble, \
    no closing summary."

    ARGS=()
    if [ "''${1:-}" = "--daily" ]; then
      ARGS=(--prompt "$DAILY_PROMPT")
    fi

    HAS_WINDOWS=$(swaymsg -t get_tree | jq -r "
      [.. | objects |
        select(.type == \"workspace\" and .name == \"$WORKSPACE\") |
        .. | objects |
        select(.type == \"con\" and .app_id != null)
      ] | length
    " 2>/dev/null)

    if [ "$HAS_WINDOWS" -gt 0 ]; then
      swaymsg "workspace number $WORKSPACE"
      exit 0
    fi

    CMD="alacritty --working-directory $HOME/Notes -e ocp"
    for a in ''${ARGS+"''${ARGS[@]}"}; do
      CMD+=" $(printf '%q' "$a")"
    done

    swaymsg "workspace number $WORKSPACE; exec $CMD"
  '';

  session-apps =
    let
      autostartWorkspaces = lib.filterAttrs (_: v: v ? autostart) workspaces;
      ordered = lib.sort (a: b: a.value.autostart < b.value.autostart) (
        lib.attrsToList autostartWorkspaces
      );
      launcherFor =
        n: v:
        if v ? launcher then
          "${v.launcher}${lib.optionalString (v ? autostartArgs) " ${v.autostartArgs}"}"
        else
          "launch-or-focus ${v.app} ${n} ${v.launch}";
      firstTarget = wsTarget (lib.head ordered).name;

      namelessWorkspaces = lib.filterAttrs (_: v: v.nameless or false) workspaces;
      renameNameless = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          n: _: ''swaymsg 'rename workspace number ${n} to "${n}:"' 2>/dev/null || true''
        ) namelessWorkspaces
      );
    in
    pkgs.writeShellScriptBin "session-apps" ''
      #!/usr/bin/env bash
      ${renameNameless}

      ${lib.concatMapStringsSep "\nsleep 1.5\n" (e: launcherFor e.name e.value) ordered}

      sleep 1.5
      swaymsg "workspace number ${firstTarget}"
    '';

  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    #!/usr/bin/env bash
    CHOICE=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | ${config.launcher.dmenu} --prompt-text "power")
    [ -z "$CHOICE" ] && exit
    case "$CHOICE" in
      Lock)     swaylock -f ;;
      Logout)   swaymsg exit ;;
      Suspend)  swaylock -f && systemctl suspend ;;
      Reboot)   systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
    esac
  '';

  sunshine-stream = pkgs.writeShellScriptBin "sunshine-stream" ''
    #!/usr/bin/env bash

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

      swaymsg create_output HEADLESS
      sleep 0.5

      swaymsg output HEADLESS-1 resolution "$RES"

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
        swaymsg 'workspace number 9; move workspace to output eDP-1' || true
        kanshictl switch single || true
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

  scrcpy-stream = pkgs.writeShellScriptBin "scrcpy-stream" ''
    #!/usr/bin/env bash

    ACTION="''${1:-toggle}"

    ADB=${pkgs.android-tools}/bin/adb
    SCRCPY=${pkgs.scrcpy}/bin/scrcpy

    list_devices() {
      "$ADB" devices -l 2>/dev/null
    }

    count_devices() {
      "$ADB" devices 2>/dev/null | awk 'NR>1 && NF>0 && !/attached/ {count++} END {print count+0}'
    }

    has_usb_device() {
      "$ADB" devices -l 2>/dev/null | awk 'NR>1 && NF>0 && !/attached/ && $1 !~ /:/ {count++} END {exit count==0}'
    }

    has_device() {
      [ "$(count_devices)" -gt 0 ] 2>/dev/null
    }

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
        swaymsg "[app_id=\"scrcpy\"] focus" 2>/dev/null || true
        exit 0
      fi

      "$ADB" start-server 2>/dev/null

      if ! has_device; then
        notify-send -u critical "scrcpy" "No Android device detected via ADB\nConnect your phone or run 'scrcpy-stream connect <ip>' for wireless."
        exit 1
      fi

      swaymsg 'workspace number 10'

      $SCRCPY \
        --turn-screen-off \
        --max-size 1080 \
        --stay-awake \
        --no-audio \
        --window-title "Android (scrcpy)" &

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

  rename-workspace = pkgs.writeShellScriptBin "rename-workspace" ''
        #!/usr/bin/env bash
        WS=$(swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        NUM=$(echo "$WS" | grep -oP '^\d+')
        default_name() {
          case "$1" in
    ${
      lib.concatStrings (
        lib.mapAttrsToList (
          n: v: lib.optionalString (v.nameless or false) "        ${n}) echo \"${n}:\" ;;\n"
        ) workspaces
      )
    }        *) echo "$1" ;;
          esac
        }

        LABEL=$(echo | ${config.launcher.dmenu} --require-match false --prompt-text "New name:")
        if [ -z "$LABEL" ]; then
          [ -n "$NUM" ] && swaymsg rename workspace to "$(default_name "$NUM")"
          exit 0
        fi
        if [ -n "$NUM" ]; then
          swaymsg rename workspace to "$NUM: $LABEL"
        else
          swaymsg rename workspace to "$LABEL"
        fi
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

        CUR_OUT=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        CUR_WS=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .current_workspace // empty')

        [ -n "$CUR_WS" ] || exit 0

        swaymsg focus output "$DIRECTION" >/dev/null
        ADJ_OUT=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        ADJ_WS=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .current_workspace // empty')

        if [ "$ADJ_OUT" = "$CUR_OUT" ] || [ -z "$ADJ_WS" ]; then
          swaymsg focus output "$CUR_OUT" >/dev/null
          swaymsg workspace "$CUR_WS" >/dev/null
          exit 0
        fi

        swaymsg move workspace to output "$CUR_OUT" >/dev/null
        swaymsg focus output "$CUR_OUT" >/dev/null
        swaymsg workspace "$CUR_WS" >/dev/null
        swaymsg move workspace to output "$ADJ_OUT" >/dev/null

        swaymsg focus output "$CUR_OUT" >/dev/null
        swaymsg workspace "$ADJ_WS" >/dev/null

        eval "$(${pkgs.jq}/bin/jq -r --arg out "$CUR_OUT" '
          .[] | select(.name == $out) |
          "CURSOR_X=\(.rect.x + .rect.width / 2 | floor)
    CURSOR_Y=\(.rect.y + .rect.height / 2 | floor)"
        ' < <(swaymsg -t get_outputs))"
        swaymsg seat seat0 cursor set "$CURSOR_X" "$CURSOR_Y" >/dev/null
  '';

  screencast-idle-inhibit = pkgs.writeShellScriptBin "screencast-idle-inhibit" ''
    #!/usr/bin/env bash
    set -uo pipefail

    INHIBIT_PID=""

    casting() {
      ${pkgs.pipewire}/bin/pw-dump 2>/dev/null | ${pkgs.jq}/bin/jq -e '
        [ .[]
          | select(.type == "PipeWire:Interface:Node")
          | select((.info.props."node.name" // "") | startswith("xdpw-stream-"))
        ] | length > 0' >/dev/null
    }

    release() {
      if [ -n "$INHIBIT_PID" ]; then
        kill "$INHIBIT_PID" 2>/dev/null || true
        INHIBIT_PID=""
      fi
    }
    trap 'release; exit 0' TERM INT

    while true; do
      if casting; then
        if [ -z "$INHIBIT_PID" ] || ! kill -0 "$INHIBIT_PID" 2>/dev/null; then
          systemd-inhibit --what=idle \
            --who="screencast-idle-inhibit" \
            --why="Screen sharing in progress" \
            sleep infinity &
          INHIBIT_PID=$!
        fi
      else
        release
      fi
      sleep 5
    done
  '';
in
{
  imports = [
    ./waybar.nix
    ./kanshi.nix
    ./mako.nix
    ./swaylock.nix
    ./tofi.nix
    ./bluetooth.nix
  ];

  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  home.packages = with pkgs; [

    wdisplays
    j
    nice-dcv-client
    swayr
    jq
    autotiling-rs
    polkit_gnome

    flameshot
    grim
    slurp
    wl-clipboard
    xdg-utils
    wifitui

    launch-or-focus
    yazi-launcher
    helix-launcher
    opencode-launcher
    session-apps
    power-menu
    rename-workspace

    sunshine-stream
    swap-workspace-output
    scrcpy-stream
    volume-notify
    brightness-notify
    screencast-idle-inhibit

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
      menu = config.launcher.drun;

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
        inner = 15;
        outer = 15;
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

      assigns = lib.mapAttrs (_: v: [ { app_id = v.app; } ]) (lib.filterAttrs (_: v: v ? app) workspaces);

      window.commands = [
        {
          criteria = {
            app_id = "flameshot";
          };
          command = "floating enable";
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

        {
          command = "swayidle -w timeout 300 'swaylock -f' timeout 600 'swaymsg \"output * power off\"' resume 'swaymsg \"output * power on\"' before-sleep 'swaylock -f'";
        }

        {
          command = "${screencast-idle-inhibit}/bin/screencast-idle-inhibit";
        }

        {
          command = "export XCURSOR_THEME=${cursorName}";
          always = true;
        }
        {
          command = "export XCURSOR_SIZE=${cursorSize}";
          always = true;
        }

        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }

        { command = "swayr daemon"; }

        { command = "autotiling-rs"; }

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

        {
          command = "gsettings set org.gnome.desktop.interface cursor-theme '${cursorName}'";
          always = true;
        }
        {
          command = "gsettings set org.gnome.desktop.interface cursor-size ${cursorSize}";
          always = true;
        }

        { command = "${session-apps}/bin/session-apps"; }
      ];

      keybindings = {

        "Mod4+Return" = "exec alacritty";
        "Mod4+w" = "kill";

        "Mod4+p" = "floating enable, sticky enable";
        "Mod4+space" = "exec ${config.launcher.drun}";
        "Mod4+Shift+c" = "reload";
        "Mod4+Shift+e" = "exec power-menu";
        "Mod4+Escape" = "exec swaylock -f";

        "XF86MonBrightnessUp" = "exec brightness-notify up";
        "XF86MonBrightnessDown" = "exec brightness-notify down";

        "XF86AudioRaiseVolume" = "exec volume-notify up";
        "XF86AudioLowerVolume" = "exec volume-notify down";
        "XF86AudioMute" = "exec volume-notify mute";
        "XF86AudioMicMute" = "exec volume-notify mic";

        "Mod4+Shift+s" = "exec flameshot gui";
        "Mod4+Shift+x" = "exec grim - | wl-copy";
        "Mod4+Shift+a" = "exec grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png";

        "Mod4+v" =
          "exec sh -c 'cliphist list | ${config.launcher.dmenu} --prompt-text \"clip\" | cliphist decode | wl-copy'";

        "Mod4+h" = "focus left";
        "Mod4+j" = "focus down";
        "Mod4+k" = "focus up";
        "Mod4+l" = "focus right";
        "Mod4+Left" = "focus left";
        "Mod4+Down" = "focus down";
        "Mod4+Up" = "focus up";
        "Mod4+Right" = "focus right";

        "Mod4+Shift+h" = "move left";
        "Mod4+Shift+j" = "move down";
        "Mod4+Shift+k" = "move up";
        "Mod4+Shift+l" = "move right";
        "Mod4+Shift+Left" = "move left";
        "Mod4+Shift+Down" = "move down";
        "Mod4+Shift+Up" = "move up";
        "Mod4+Shift+Right" = "move right";

        "Mod4+Tab" = "workspace next";
        "Mod4+Shift+Tab" = "workspace prev";

        "Mod4+Shift+b" = "splith";
        "Mod4+Shift+v" = "splitv";
        "Mod4+u" = "layout stacking";
        "Mod4+i" = "layout tabbed";
        "Mod4+o" = "layout toggle split";
        "Mod4+Shift+f" = "fullscreen";
        "Mod4+Shift+space" = "floating toggle";
        "Mod4+a" = "focus parent";

        "Mod4+Shift+minus" = "move scratchpad";
        "Mod4+minus" = "scratchpad show";

        "Mod4+Shift+r" = "exec rename-workspace";

        "Mod4+Shift+d" = "exec display-mode-selector";
        "Mod4+Ctrl+1" = "exec kanshi-switch single";
        "Mod4+Ctrl+2" = "exec kanshi-switch docked";
        "Mod4+Ctrl+3" = "exec kanshi-switch triple";

        "Mod4+Shift+p" = "exec sunshine-stream toggle";
        "Mod4+Ctrl+p" =
          "exec sunshine-stream status && notify-send 'Sunshine' \"$(sunshine-stream status)\"";

        "Mod4+Shift+o" = "exec scrcpy-stream toggle";
        "Mod4+Ctrl+o" = "exec scrcpy-stream status && notify-send 'scrcpy' \"$(scrcpy-stream status)\"";

        "Mod4+Ctrl+Left" = "exec swap-workspace-output left";
        "Mod4+Ctrl+Right" = "exec swap-workspace-output right";

        "Mod4+Ctrl+equal" = "gaps inner current plus 4";
        "Mod4+Ctrl+minus" = "gaps inner current minus 4";
        "Mod4+Ctrl+Shift+equal" = "gaps outer current plus 4";
        "Mod4+Ctrl+Shift+minus" = "gaps outer current minus 4";
        "Mod4+Ctrl+0" = "gaps inner current set 0, gaps outer current set 0";
        "Mod4+Ctrl+9" = "gaps inner current set 8, gaps outer current set 4";

        "Mod4+F1" = "exec systemctl --user kill --kill-whom=main -s SIGUSR1 waybar.service";

        "Mod4+r" = "mode resize";
      }

      // lib.listToAttrs (
        lib.concatMap (
          n:
          let
            key = if n == "10" then "0" else n;
            target = wsTarget n;
          in
          [
            (lib.nameValuePair "Mod4+${key}" "workspace number ${target}")
            (lib.nameValuePair "Mod4+Shift+${key}" "move container to workspace number ${target}")
          ]
        ) (map toString (lib.range 1 10))
      )
      // lib.mapAttrs' (
        n: v: lib.nameValuePair "Mod4+${v.key}" "exec launch-or-focus ${v.app} ${n} ${v.launch}"
      ) (lib.filterAttrs (_: v: (v ? app) && (v ? key)) workspaces)
      // lib.mapAttrs' (_: v: lib.nameValuePair "Mod4+${v.key}" "exec ${v.launcher}") (
        lib.filterAttrs (_: v: (v ? launcher) && (v ? key)) workspaces
      );

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

      output * bg #${colors.base00} solid_color
      bindgesture swipe:4:left workspace prev
      bindgesture swipe:4:right workspace next

      include /etc/sway/config-vars.d/*
      include /etc/sway/config.d/*
    '';
  };
}
