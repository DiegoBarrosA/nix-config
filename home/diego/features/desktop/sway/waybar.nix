{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;
  inherit (config) fontProfiles;

  # Decode a \uXXXX escape to the actual Unicode character
  u = code: builtins.fromJSON ''"\u${code}"'';

  workspaces = import ./workspaces.nix { inherit lib; };

  # FA7 Free Solid icons
  iconCb = u "f3ed"; # shield-alt
  iconLock = u "f023"; # lock
  iconServer = u "f233"; # server
  iconSync = u "f021"; # sync
  iconShare = u "f1e0"; # share-alt

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

  # Drawer leader for the resources group: a bare microchip icon so cpu/memory
  # stay hidden until the group is hovered.
  waybar-sys-icon = pkgs.writeShellScriptBin "waybar-sys-icon" ''
    printf '{"text":"%s","tooltip":"cpu / memory"}\n' "${u "f2db"}"
  '';

  waybar-jocalsend = pkgs.writeShellScriptBin "waybar-jocalsend" ''
    CHOICE=$(printf 'Send file\nReceive\nOpen TUI' | ${config.launcher.dmenu} --prompt-text "jocalsend")
    [ -z "$CHOICE" ] && exit 0
    case "$CHOICE" in
      "Send file")
        # Free-text prompt; the `echo` matters, as tofi exits without drawing
        # on empty stdin.
        PATH_TO_SEND=$(echo | ${config.launcher.dmenu} --require-match false --prompt-text "file path:")
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

  # World clocks: one widget per city, shown in the expanding clocks drawer.
  worldClocks = [
    {
      name = "palo-alto";
      label = "LA";
      tz = "America/Los_Angeles";
    }
    {
      name = "london";
      label = "LDN";
      tz = "Europe/London";
    }
    {
      name = "paris";
      label = "PAR";
      tz = "Europe/Paris";
    }
    {
      name = "australia";
      label = "SYD";
      tz = "Australia/Sydney";
    }

    {
      name = "santiago";
      label = "STGO";
      tz = "America/Santiago";
    }
  ];

  worldClock =
    c:
    pkgs.writeShellScriptBin "worldclock-${c.name}" ''
      printf '{"text":"%s","tooltip":"%s  %s"}\n' \
        "${c.label} $(TZ='${c.tz}' date '+%H:%M')" \
        "${c.label}" \
        "$(TZ='${c.tz}' date '+%a %b %d')"
    '';

  worldClockModules = lib.listToAttrs (
    map (c: {
      name = "custom/worldclock-${c.name}";
      value = {
        exec = "${lib.getExe (worldClock c)}";
        interval = 1;
        return-type = "json";
      };
    }) worldClocks
  );

  # Location-aware clock: renders the plain date/time; the current city is kept
  # in the tooltip. Reads the system timezone (kept in sync with the physical
  # location by NixOS' services.localtimed via geoclue2) so the display picks
  # up a timezone change on the next one-second tick.
  waybar-location-clock = pkgs.writeShellScriptBin "waybar-location-clock" ''
    set -eu

    # systemd-timedated retargets /etc/localtime when localtimed updates it.
    tz=$(readlink /etc/localtime 2>/dev/null || true)
    case "$tz" in
      *share/zoneinfo/*)
        tz=''${tz##*share/zoneinfo/}
        ;;
      *)
        tz=$(timedatectl show -p Timezone --value 2>/dev/null || true)
        ;;
    esac
    [ -n "$tz" ] || tz="UTC"

    case "$tz" in
      America/Santiago)    city="Santiago" ;;
      America/Los_Angeles) city="Palo Alto" ;;
      Europe/London)       city="London" ;;
      Europe/Paris)        city="Paris" ;;
      Australia/Sydney)    city="Sydney" ;;
      *) city=$(printf '%s' "$tz" | sed 's|.*/||; s|_| |g') ;;
    esac

    time=$(date '+%a %b %d  %H:%M')

    if [ "$tz" = "America/Santiago" ]; then
      class="home"
    else
      class="away"
    fi

    now="$city  ($tz)"
    calendar=$(cal)

    ${lib.getExe pkgs.jq} -cn \
      --arg text "$time" \
      --arg class "$class" \
      --arg now "$now" \
      --arg calendar "$calendar" \
      '{text: $text, class: $class, tooltip: "<tt><small>\($calendar)</small></tt>\n<small>\($now)</small>"}'
  '';
in
{
  programs.waybar = {
    enable = true;

    systemd = {
      enable = true;
      targets = [ "sway-session.target" ];
    };

    settings = [
      (
        {
          layer = "top";
          position = "top";
          height = 36;
          spacing = 0;
          modules-left = [
            "sway/workspaces"
            "sway/mode"
          ];
          modules-center = [
            "sway/window"
          ];
          modules-right = [
            "tray"
            "sway/language"
            "pulseaudio"
            "bluetooth"
            "network"
            "battery"
            "group/resources"
            "group/status"
            "group/clocks"
          ];

          # Drawer group: the first module is always shown; the rest tuck into a
          # drawer revealed on hover. "global time" lives here, expanding out of
          # the location clock. Reveals leftward: the group sits at the far right
          # edge, so a rightward drawer would slide off-screen.
          "group/clocks" = {
            orientation = "horizontal";
            drawer = {
              transition-duration = 300;
              transition-left-to-right = false;
              children-class = "clocks-child";
            };
            modules = [
              "custom/location-clock"
            ]
            ++ (map (c: "custom/worldclock-${c.name}") worldClocks);
          };

          "group/status" = {
            orientation = "horizontal";
            drawer = {
              transition-duration = 300;
              children-class = "status-child";
            };
            modules = [
              "custom/cb"
              "custom/tailscale"
              "custom/cobalto"
              "custom/syncthing"
              "custom/jocalsend-icon"
            ];
          };

          # System monitors are hidden behind a bare icon by default; hover to
          # reveal cpu/memory usage.
          "group/resources" = {
            orientation = "horizontal";
            drawer = {
              transition-duration = 300;
              children-class = "resources-child";
            };
            modules = [
              "custom/sys-icon"
              "cpu"
              "memory"
            ];
          };

          "sway/workspaces" = workspaces.waybarWorkspaces;

          "sway/mode" = {
            format = "<span style=\"italic\">{}</span>";
          };

          "sway/window" = {
            max-length = 50;
          };

          tray = {
            icon-size = 18;
            spacing = 10;
          };

          "custom/location-clock" = {
            exec = "${lib.getExe waybar-location-clock}";
            interval = 1;
            return-type = "json";
          };

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

          "custom/sys-icon" = {
            exec = "${lib.getExe waybar-sys-icon}";
            interval = "once";
            return-type = "json";
          };

          cpu = {
            format = "${u "f2db"} {usage}%";
            format-alt = "${u "f2db"} {avg_frequency} GHz";
            tooltip = true;
            interval = 5;
            on-click = "alacritty -e ${pkgs.bottom}/bin/btm";
          };

          memory = {
            format = "${u "f538"} {}%";
            format-alt = "${u "f538"} {used:0.1f}GiB/{total:0.1f}GiB";
            tooltip-format = "{used:0.1f}G / {total:0.1f}G";
            interval = 5;
            on-click = "alacritty -e ${pkgs.bottom}/bin/btm";
          };

          backlight = {
            format = "{icon} {percent}%";
            format-icons = [ "${u "f185"}" ];
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon}";
            format-charging = "${u "e55b"}";
            format-plugged = "${u "f1e6"}";
            format-icons = [
              "${u "f244"}"
              "${u "f243"}"
              "${u "f242"}"
              "${u "f241"}"
              "${u "f240"}"
            ];
          };

          network = {
            format-wifi = "${u "f1eb"}";
            format-ethernet = "${u "f796"}";
            format-disconnected = "${u "f071"} Disconnected";
            tooltip-format-wifi = "{essid} ({signalStrength}%)";
            tooltip-format-ethernet = "{ifname}";
            on-click = "alacritty -e wifitui";
          };

          pulseaudio = {
            format = "{icon}";
            format-bluetooth = "${u "f294"}";
            format-muted = "${u "f6a9"}";
            format-icons = {
              headphone = "${u "f025"}";
              default = [
                "${u "f026"}"
                "${u "f027"}"
                "${u "f028"}"
              ];
            };
            on-click = "alacritty -e wiremix";
          };

          bluetooth = {
            # Icons: f294 = bluetooth-b (brand). Empty format-off/disabled hides
            # the module when the controller is off, so it only shows when active.
            format = "${u "f294"}";
            format-on = "${u "f294"}";
            format-off = "";
            format-disabled = "";
            format-connected = "${u "f294"}";
            format-connected-battery = "${u "f294"} {device_battery_percentage}%";
            format-no-controller = "";
            tooltip-format = "{controller_alias}\t{controller_address}\n\n{status}";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
            on-click = "alacritty -e bluetuith";
          };
        }
        // worldClockModules
      )
    ];

    style = ''
      /* Colorscheme: ${config.colorscheme.type} */

      /* Reset GTK styling that might leak in */
      * {
        font-family:  "Fantasque Sans Mono","Font Awesome 7 Brands", "Font Awesome 7 Free Solid";
        font-size: 18px;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background-color: #${colors.base00};
        color: #${colors.base05};
        border: none;
        border-radius: 0;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      window#waybar #workspaces button {
        font-family: "Font Awesome 7 Brands", "Font Awesome 7 Free Solid";
        font-weight: normal;
        padding: 0 8px;
        background-image: none;
        border: none;
        border-radius: 0;
        box-shadow: none;
        outline: none;
        text-shadow: none;
        border-image: none;
        background-color: transparent;
        color: #${colors.base04};
        -gtk-icon-effect: none;
      }

      window#waybar #workspaces button * {
        text-shadow: none;
        font-family: "Font Awesome 7 Brands", "Font Awesome 7 Free Solid";
        font-weight: normal;
      }

      window#waybar #workspaces button label {
        font-family: "Font Awesome 7 Brands", "Font Awesome 7 Free Solid", "Fantasque Sans Mono";
      }

      window#waybar #workspaces button.urgent:not(.focused),
      window#waybar #workspaces button.active.urgent:not(.focused) {
        background-color: #${colors.base08};
        color: #${colors.base00};
        box-shadow: none;
      }

      window#waybar #workspaces button.urgent:not(.focused) *,
      window#waybar #workspaces button.active.urgent:not(.focused) * {
        color: #${colors.base00};
      }

      window#waybar #workspaces button:hover {
        background-color: #${colors.base01};
        background-image: none;
        color: #${colors.base05};
        box-shadow: none;
      }

      window#waybar #workspaces button.focused,
      window#waybar #workspaces button.focused *,
      window#waybar #workspaces button.focused label,
      window#waybar #workspaces button.active,
      window#waybar #workspaces button.active * {
        color: #${colors.base0D};
        font-weight: 400;
      }

      window#waybar #workspaces button.focused,
      window#waybar #workspaces button.active {
        background-color: #${colors.base01};
        background-image: none;
        box-shadow: none;
      }

      #mode {
        background-color: #${colors.base0E};
        color: #${colors.base00};
        padding: 0 10px;
      }

      #window {
        color: #${colors.base04};
        padding: 0 10px;
      }

      #battery,
      #cpu,
      #memory,
      #backlight,
      #network,
      #pulseaudio,
      #bluetooth,
      #language,
      #tray {
        padding: 0 12px;
        color: #${colors.base05};
      }

      #custom-location-clock {
        padding: 0 12px;
        color: #${colors.base05};
        font-weight: 500;
      }

      #custom-location-clock.away {
        color: #${colors.base0D};
      }

      #battery.warning:not(.charging) {
        color: #${colors.base09};
      }

      #battery.critical:not(.charging) {
        background-color: #${colors.base0F};
        color: #${colors.base00};
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink {
        to {
          background-color: #${colors.base00};
          color: #${colors.base0F};
        }
      }

      #cpu {
        color: #${colors.base05};
      }

      #memory {
        color: #${colors.base05};
      }

      #backlight {
        color: #${colors.base0A};
      }

      #network.disconnected {
        color: #${colors.base0F};
      }

      #pulseaudio.muted {
        color: #${colors.base03};
      }

      #bluetooth.connected {
        color: #${colors.base0D};
      }

      #bluetooth.discovering,
      #bluetooth.discoverable,
      #bluetooth.pairable {
        color: #${colors.base0A};
      }

      #bluetooth.off,
      #bluetooth.disabled {
        color: #${colors.base03};
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #${colors.base0F};
      }

      tooltip {
        background-color: #${colors.base00};
        border: 1px solid #${colors.base0D};
        border-radius: 4px;
      }

      tooltip label {
        color: #${colors.base05};
      }

      /* Bottom status bar module states */
      #custom-cb,
      #custom-tailscale,
      #custom-cobalto,
      #custom-syncthing,
      #custom-jocalsend-icon,
      #custom-sys-icon,
      #custom-worldclock-palo-alto,
      #custom-worldclock-london,
      #custom-worldclock-paris,
      #custom-worldclock-australia {
        padding: 0 12px;
        color: #${colors.base05};
      }

      #custom-cb.ok,
      #custom-tailscale.ok,
      #custom-cobalto.ok,
      #custom-syncthing.ok {
        color: #${colors.base05};
      }

      #custom-cb.error,
      #custom-tailscale.error,
      #custom-cobalto.error,
      #custom-syncthing.error {
        color: #${colors.base08};
      }

      #custom-tailscale.warning,
      #custom-syncthing.warning {
        color: #${colors.base09};
      }

      #custom-tailscale.off,
      #custom-syncthing.off {
        color: #${colors.base03};
      }

      #custom-syncthing.syncing {
        color: #${colors.base0D};
      }
    '';
  };

  home.packages = [
    pkgs.jocalsend
    waybar-cb
    waybar-tailscale
    waybar-cobalto
    waybar-syncthing
    waybar-jocalsend-icon
    waybar-jocalsend
    waybar-sys-icon
    waybar-location-clock
  ]
  ++ (map worldClock worldClocks);
}
