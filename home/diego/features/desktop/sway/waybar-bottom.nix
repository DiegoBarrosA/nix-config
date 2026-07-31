{
  config,
  lib,
  pkgs,
  ...
}:
let
  u = code: builtins.fromJSON ''"\u${code}"'';

  # FA7 Free Solid icons
  iconCb = u "f3ed"; # shield-alt
  iconLock = u "f023"; # lock
  iconServer = u "f233"; # server
  iconSync = u "f021"; # sync
  iconShare = u "f1e0"; # share-alt
  iconCpu = u "f2db"; # microchip
  iconMemory = u "f538"; # memory

  waybar-cb = pkgs.writeShellScriptBin "waybar-cb" ''
    if systemctl is-active --quiet cbagentd; then
      printf '{"text":"%s","class":"ok","tooltip":"CB agent running"}\n' "${iconCb}"
    else
      printf '{"text":"%s","class":"error","tooltip":"CB agent not running"}\n' "${iconCb}"
    fi
  '';

  waybar-tailscale = pkgs.writeShellScriptBin "waybar-tailscale" ''
    DATA=$(${lib.getExe pkgs.tailscale} status --json 2>/dev/null) || DATA=""

    if [ -z "$DATA" ]; then
      printf '{"text":"%s","class":"error","tooltip":"tailscale unavailable"}\n' "${iconLock}"
      exit 0
    fi

    STATE=$(printf '%s' "$DATA" | ${lib.getExe pkgs.jq} -r '.BackendState // "unknown"')
    PEERS=$(printf '%s' "$DATA" | ${lib.getExe pkgs.jq} '[.Peer // {} | to_entries[] | select(.value.Online == true)] | length')

    case "$STATE" in
      Running)
        printf '{"text":"%s","class":"ok","tooltip":"Tailscale up — %s peer(s) online"}\n' "${iconLock}" "$PEERS"
        ;;
      Stopped)
        printf '{"text":"%s","class":"off","tooltip":"Tailscale stopped"}\n' "${iconLock}"
        ;;
      NeedsLogin|NoState)
        printf '{"text":"%s","class":"warning","tooltip":"Tailscale: %s"}\n' "${iconLock}" "$STATE"
        ;;
      *)
        printf '{"text":"%s","class":"warning","tooltip":"Tailscale: %s"}\n' "${iconLock}" "$STATE"
        ;;
    esac
  '';

  waybar-cobalto = pkgs.writeShellScriptBin "waybar-cobalto" ''
    RESULT=$(ping -c 1 -W 2 cobalto 2>&1)
    if echo "$RESULT" | grep -q 'time='; then
      LATENCY=$(echo "$RESULT" | grep -oP 'time=\K[0-9.]+')
      printf '{"text":"%s","class":"ok","tooltip":"cobalto: %s ms"}\n' "${iconServer}" "$LATENCY"
    else
      printf '{"text":"%s","class":"error","tooltip":"cobalto unreachable"}\n' "${iconServer}"
    fi
  '';

  waybar-syncthing = pkgs.writeShellScriptBin "waybar-syncthing" ''
    # Resolve API key from config.xml (primary then fallback path)
    CONFIG_XML="${config.xdg.configHome}/syncthing/config.xml"
    FALLBACK_XML="$HOME/.local/state/syncthing/config.xml"

    if [ -f "$CONFIG_XML" ]; then
      APIKEY=$(grep -oP '(?<=<apikey>)[^<]+' "$CONFIG_XML" | head -1)
    elif [ -f "$FALLBACK_XML" ]; then
      APIKEY=$(grep -oP '(?<=<apikey>)[^<]+' "$FALLBACK_XML" | head -1)
    fi

    if [ -z "''${APIKEY:-}" ]; then
      printf '{"text":"%s","class":"error","tooltip":"Syncthing: API key not found"}\n' "${iconSync}"
      exit 0
    fi

    DATA=$(${lib.getExe pkgs.curl} -sf -H "X-API-Key: $APIKEY" http://127.0.0.1:8384/rest/system/connections 2>/dev/null) || DATA=""

    if [ -z "$DATA" ]; then
      printf '{"text":"%s","class":"error","tooltip":"Syncthing: not reachable"}\n' "${iconSync}"
      exit 0
    fi

    CONNECTED=$(printf '%s' "$DATA" | ${lib.getExe pkgs.jq} '[.connections // {} | to_entries[] | select(.value.connected == true)] | length')
    printf '{"text":"%s","class":"ok","tooltip":"Syncthing: %s device(s) connected"}\n' "${iconSync}" "$CONNECTED"
  '';

  waybar-jocalsend-icon = pkgs.writeShellScriptBin "waybar-jocalsend-icon" ''
    printf '{"text":"%s","tooltip":"jocalsend"}\n' "${iconShare}"
  '';

  waybar-jocalsend = pkgs.writeShellScriptBin "waybar-jocalsend" ''
    CHOICE=$(printf 'Send file\nReceive\nOpen TUI' | fuzzel --dmenu --prompt "jocalsend ")
    [ -z "$CHOICE" ] && exit 0
    case "$CHOICE" in
      "Send file")
        PATH_TO_SEND=$(echo | fuzzel --dmenu --prompt "file path: ")
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

  configBottom = builtins.toJSON {
    layer = "top";
    position = "bottom";
    height = 36;
    spacing = 0;
    "modules-left" = [
      "custom/cb"
      "custom/tailscale"
      "custom/cobalto"
      "custom/syncthing"
    ];
    "modules-center" = [
      "sway/window"
    ];
    "modules-right" = [
      "sway/mode"
      "cpu"
      "memory"
      "custom/jocalsend-icon"
    ];
    "custom/cb" = {
      exec = "${lib.getExe waybar-cb}";
      interval = 30;
      return-type = "json";
    };
    "custom/tailscale" = {
      exec = "${lib.getExe waybar-tailscale}";
      interval = 15;
      return-type = "json";
    };
    "custom/cobalto" = {
      exec = "${lib.getExe waybar-cobalto}";
      interval = 60;
      return-type = "json";
    };
    "custom/syncthing" = {
      exec = "${lib.getExe waybar-syncthing}";
      interval = 30;
      return-type = "json";
      on-click = "xdg-open http://127.0.0.1:8384";
    };
    "custom/jocalsend-icon" = {
      exec = "${lib.getExe waybar-jocalsend-icon}";
      interval = "once";
      return-type = "json";
      on-click = "${lib.getExe waybar-jocalsend}";
    };
    "cpu" = {
      interval = 5;
      format = "${iconCpu} {usage}%";
      format-alt = "${iconCpu} {avg_frequency} GHz";
      on-click = "alacritty -e ${pkgs.bottom}/bin/btm";
    };
    "memory" = {
      interval = 5;
      format = "${iconMemory} {used:0.1f}GiB";
      format-alt = "${iconMemory} {used:0.1f}GiB/{total:0.1f}GiB";
      on-click = "alacritty -e ${pkgs.bottom}/bin/btm";
    };
  };
in
{
  xdg.configFile."waybar/config-bottom.json".text = configBottom;

  home.packages = [
    pkgs.jocalsend
    waybar-cb
    waybar-tailscale
    waybar-cobalto
    waybar-syncthing
    waybar-jocalsend-icon
    waybar-jocalsend
  ];

  systemd.user.services.waybar-bottom = {
    Unit = {
      Description = "Bottom status overlay bar";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      X-Restart-Triggers = [ (pkgs.writeText "waybar-bottom-trigger" configBottom) ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar -c ${config.xdg.configHome}/waybar/config-bottom.json -s ${config.xdg.configHome}/waybar/style.css";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
    # Restart whenever the config JSON or any of the embedded script paths change
  };
}
