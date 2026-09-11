{
  config,
  lib,
  pkgs,
  ...
}:
let
  dmenu = config.launcher.dmenu;
  inherit (config.colorscheme) colors;

  # Structure follows rofi's own bundled Arc-Dark.rasi (share/rofi/themes/Arc-Dark.rasi)
  # almost verbatim -- same selector syntax (dot-separated states) and property set,
  # just with our colorscheme swapped in. That theme is known-good on every rofi
  # release; ours was going fully white for reasons a from-scratch theme couldn't
  # pin down, so we're piggybacking on proven structure instead of guessing further.
  rofiTheme = pkgs.writeText "sway-menu.rasi" ''
    * {
        foreground:                   #${colors.base05};
        normal-foreground:            @foreground;
        background:                   #${colors.base00};
        normal-background:            @background;
        alternate-normal-background:  @background;
        alternate-normal-foreground:  @foreground;
        border-color:                 #${colors.base0D};
        active-foreground:            #${colors.base0D};
        active-background:            @background;
        urgent-foreground:            #${colors.base08};
        urgent-background:            @background;
        alternate-active-background:  @active-background;
        alternate-active-foreground:  @active-foreground;
        alternate-urgent-background:  @urgent-background;
        alternate-urgent-foreground:  @urgent-foreground;
        selected-normal-background:   #${colors.base0D};
        selected-normal-foreground:   #${colors.base00};
        selected-active-background:   #${colors.base0D};
        selected-active-foreground:   #${colors.base00};
        selected-urgent-background:   #${colors.base08};
        selected-urgent-foreground:   #${colors.base00};
        separatorcolor:               @border-color;
        spacing:                      2;
    }
    window {
        background-color: @background;
        border:           1;
        padding:          5;
    }
    mainbox {
        background-color: @background;
        border:            0;
        padding:           0;
        children:          [ "inputbar", "message", "listview", "mode-switcher" ];
    }
    message {
        background-color: @background;
        border:            2px 0px 0px ;
        border-color:      @separatorcolor;
        padding:           1px ;
    }
    textbox {
        background-color: @background;
        text-color:        @foreground;
    }
    listview {
        background-color: @background;
        fixed-height:      0;
        border:            2px 0px 0px ;
        border-color:      @separatorcolor;
        spacing:           2px ;
        scrollbar:         false;
        padding:           2px 0px 0px ;
    }
    element {
        border:  0;
        padding: 1px ;
    }
    element-text {
        background-color: inherit;
        text-color:       inherit;
    }
    element.normal.normal {
        background-color: @normal-background;
        text-color:       @normal-foreground;
    }
    element.normal.urgent {
        background-color: @urgent-background;
        text-color:       @urgent-foreground;
    }
    element.normal.active {
        background-color: @active-background;
        text-color:       @active-foreground;
    }
    element.selected.normal {
        background-color: @selected-normal-background;
        text-color:       @selected-normal-foreground;
    }
    element.selected.urgent {
        background-color: @selected-urgent-background;
        text-color:       @selected-urgent-foreground;
    }
    element.selected.active {
        background-color: @selected-active-background;
        text-color:       @selected-active-foreground;
    }
    element.alternate.normal {
        background-color: @alternate-normal-background;
        text-color:       @alternate-normal-foreground;
    }
    element.alternate.urgent {
        background-color: @alternate-urgent-background;
        text-color:       @alternate-urgent-foreground;
    }
    element.alternate.active {
        background-color: @alternate-active-background;
        text-color:       @alternate-active-foreground;
    }
    scrollbar {
        width:        4px ;
        border:       0;
        handle-color: @normal-foreground;
        handle-width: 8px ;
        padding:      0;
    }
    mode-switcher {
        background-color: @background;
        border:            2px 0px 0px ;
        border-color:      @separatorcolor;
    }
    button {
        background-color: @background;
        spacing:           0;
        text-color:        @normal-foreground;
    }
    button.selected {
        background-color: @selected-normal-background;
        text-color:       @selected-normal-foreground;
    }
    inputbar {
        background-color: @background;
        spacing:           0;
        text-color:        @normal-foreground;
        padding:           1px ;
        children:          [ prompt,textbox-prompt-colon,entry,case-indicator ];
    }
    case-indicator {
        background-color: @background;
        spacing:           0;
        text-color:        @normal-foreground;
    }
    entry {
        background-color: @background;
        spacing:           0;
        text-color:        @normal-foreground;
    }
    prompt {
        background-color: @background;
        spacing:           0;
        text-color:        @normal-foreground;
    }
    textbox-prompt-colon {
        background-color: @background;
        expand:            false;
        str:               ":";
        margin:            0px 0.3em 0em 0em ;
        text-color:        @normal-foreground;
    }
  '';

  workspaces = import ./workspaces.nix { inherit lib; };

  workspaceLabel =
    n: v:
    if v ? app then v.app else if v ? launcher then v.launcher else "workspace ${n}";

  workspace-modi = pkgs.writeShellScriptBin "workspace-modi" ''
    set -eu
    if [ "''${ROFI_RETV:-0}" = "1" ]; then
      swaymsg "workspace number ''${ROFI_INFO:-1}"
      exit 0
    fi
    ${lib.concatStrings (
      lib.mapAttrsToList (
        n: v: "printf '%s\\0info\\x1f%s\\n' \"${n}: ${workspaceLabel n v}\" \"${n}\"\n"
      ) workspaces.registry
    )}
  '';

  status-modi = pkgs.writeShellScriptBin "status-modi" ''
    set -eu

    tailscale_line() {
      DATA=$(${lib.getExe pkgs.tailscale} status --json 2>/dev/null) || { echo "Tailscale: unavailable"; return; }
      STATE=$(printf '%s' "$DATA" | ${lib.getExe pkgs.jq} -r '.BackendState // "unknown"')
      PEERS=$(printf '%s' "$DATA" | ${lib.getExe pkgs.jq} '[.Peer // {} | to_entries[] | select(.value.Online == true)] | length')
      echo "Tailscale: $STATE ($PEERS peers)"
    }

    syncthing_line() {
      CONFIG_XML="${config.xdg.configHome}/syncthing/config.xml"
      FALLBACK_XML="$HOME/.local/state/syncthing/config.xml"
      if [ -f "$CONFIG_XML" ]; then APIKEY=$(grep -oP '(?<=<apikey>)[^<]+' "$CONFIG_XML" | head -1)
      elif [ -f "$FALLBACK_XML" ]; then APIKEY=$(grep -oP '(?<=<apikey>)[^<]+' "$FALLBACK_XML" | head -1)
      fi
      [ -z "''${APIKEY:-}" ] && { echo "Syncthing: no API key"; return; }
      DATA=$(${lib.getExe pkgs.curl} -sf -H "X-API-Key: $APIKEY" http://127.0.0.1:8384/rest/system/connections 2>/dev/null) || { echo "Syncthing: unreachable"; return; }
      CONNECTED=$(printf '%s' "$DATA" | ${lib.getExe pkgs.jq} '[.connections // {} | to_entries[] | select(.value.connected == true)] | length')
      echo "Syncthing: $CONNECTED device(s) connected"
    }

    cobalto_line() {
      RESULT=$(ping -c 1 -W 2 cobalto 2>&1)
      if echo "$RESULT" | grep -q 'time='; then
        echo "cobalto: up ($(echo "$RESULT" | grep -oP 'time=\K[0-9.]+') ms)"
      else
        echo "cobalto: unreachable"
      fi
    }

    cb_line() {
      systemctl is-active --quiet cbagentd && echo "CB agent: running" || echo "CB agent: not running"
    }

    audio_line() {
      VOL_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || { echo "Audio: no sink"; return; }
      echo "Audio: $VOL_INFO"
    }

    battery_line() {
      BAT=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1) || { echo "Battery: n/a"; return; }
      STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
      echo "Battery: $BAT% ($STATUS)"
    }

    network_line() {
      nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | grep -v ':unmanaged$' | grep ':connected:' \
        | awk -F: '{print "Network: " $1 " (" $3 ")"}' | head -1 || echo "Network: disconnected"
    }

    row() {
      # row "display text" "action-key"
      printf '%s\0info\x1f%s\n' "$1" "$2"
    }

    if [ "''${ROFI_RETV:-0}" = "1" ]; then
      case "''${ROFI_INFO:-none}" in
        syncthing) xdg-open http://127.0.0.1:8384 & ;;
        cpu) alacritty -e ${pkgs.bottom}/bin/btm & ;;
        network) alacritty -e wifitui & ;;
        audio) alacritty -e wiremix & ;;
        bluetooth) alacritty -e bluetuith & ;;
        jocalsend) ${lib.getExe' pkgs.util-linux "setsid"} -f jocalsend-menu >/dev/null 2>&1 & ;;
        droidcam) ${lib.getExe' pkgs.util-linux "setsid"} -f droidcam-menu >/dev/null 2>&1 & ;;
      esac
      exit 0
    fi

    row "$(date '+%A %d %B, %H:%M')" none
    row "$(tailscale_line)" none
    row "$(syncthing_line)" syncthing
    row "$(cobalto_line)" none
    row "$(cb_line)" none
    row "$(audio_line)" audio
    row "$(battery_line)" none
    row "$(network_line)" network
    row "CPU / memory" cpu
    row "Bluetooth" bluetooth
    row "Jocalsend" jocalsend
    row "Droidcam" droidcam
  '';

  jocalsend-menu = pkgs.writeShellScriptBin "jocalsend-menu" ''
    CHOICE=$(printf 'Send file\nReceive\nOpen TUI' | ${dmenu} --prompt-text "jocalsend")
    [ -z "$CHOICE" ] && exit 0
    case "$CHOICE" in
      "Send file")
        PATH_TO_SEND=$(echo | ${dmenu} --require-match false --prompt-text "file path:")
        [ -z "$PATH_TO_SEND" ] && exit 0
        alacritty -e ${lib.getExe pkgs.jocalsend} send "$PATH_TO_SEND"
        ;;
      "Receive")
        alacritty -e ${lib.getExe pkgs.jocalsend} receive
        ;;
      "Open TUI")
        alacritty -e ${lib.getExe pkgs.jocalsend}
        ;;
    esac
  '';

  droidcam-menu = pkgs.writeShellScriptBin "droidcam-menu" ''
    CHOICE=$(printf 'Connect via IP\nConnect via ADB (USB)\nConnect via iOS (usbmuxd)' | ${dmenu} --prompt-text "droidcam")
    [ -z "$CHOICE" ] && exit 0
    case "$CHOICE" in
      "Connect via IP")
        IP=$(echo | ${dmenu} --require-match false --prompt-text "phone ip:")
        [ -z "$IP" ] && exit 0
        alacritty -e droidcam-cli -a -v "$IP" 4747
        ;;
      "Connect via ADB (USB)")
        alacritty -e droidcam-cli -a -v adb 4747
        ;;
      "Connect via iOS (usbmuxd)")
        alacritty -e droidcam-cli -a -v ios 4747
        ;;
    esac
  '';

  main-menu = pkgs.writeShellScriptBin "main-menu" ''
    exec ${lib.getExe config.programs.rofi.finalPackage} -show drun
  '';
in
{
  programs.rofi = {
    enable = true;
    font = lib.mkForce "FantasqueSansM Nerd Font 22";
    modes = [
      "drun"
      {
        name = "workspace";
        path = "${lib.getExe workspace-modi}";
      }
      {
        name = "status";
        path = "${lib.getExe status-modi}";
      }
    ];
    extraConfig = {
      "sidebar-mode" = true;
      "kb-mode-next" = "Tab";
      "kb-mode-previous" = "Shift+Tab";
      "kb-element-next" = "";
      "kb-element-prev" = "";
    };
    theme = lib.mkForce "${rofiTheme}";
  };

  home.packages = [
    pkgs.jocalsend
    workspace-modi
    status-modi
    main-menu
    jocalsend-menu
    droidcam-menu
  ];
}
