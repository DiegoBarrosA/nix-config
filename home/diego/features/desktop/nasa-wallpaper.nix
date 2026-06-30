{ config, lib, pkgs, ... }:

let
  nasaApodWallpaper = pkgs.writeShellScriptBin "nasa-apod-wallpaper" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.curl pkgs.jq pkgs.awww pkgs.coreutils pkgs.gnused ]}

    # Need a Wayland session to set a wallpaper; bail quietly otherwise.
    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      echo "nasa-apod-wallpaper: no WAYLAND_DISPLAY, skipping"
      exit 0
    fi

    WALLPAPER_DIR="''${HOME}/.wallpapers"
    API_KEY="''${NASA_API_KEY:-DEMO_KEY}"
    API_URL="https://api.nasa.gov/planetary/apod?api_key=''${API_KEY}"

    mkdir -p "''${WALLPAPER_DIR}"

    # Fetch APOD metadata, capturing the HTTP status separately so we can give
    # a useful message (DEMO_KEY is rate-limited; a free key is recommended).
    RESPONSE=$(curl -s -w $'\n%{http_code}' "''${API_URL}") || {
      echo "nasa-apod-wallpaper: curl failed (no network?)"
      exit 0
    }
    HTTP_CODE=$(printf '%s' "''${RESPONSE}" | tail -n1)
    RESPONSE=$(printf '%s' "''${RESPONSE}" | sed '$d')
    if [ "''${HTTP_CODE}" != "200" ]; then
      echo "nasa-apod-wallpaper: APOD API returned HTTP ''${HTTP_CODE}" \
           "(DEMO_KEY rate-limited? set NASA_API_KEY from https://api.nasa.gov)"
      exit 0
    fi

    MEDIA_TYPE=$(echo "''${RESPONSE}" | jq -r '.media_type')
    if [ "''${MEDIA_TYPE}" != "image" ]; then
      echo "nasa-apod-wallpaper: APOD is not an image (''${MEDIA_TYPE}), skipping"
      exit 0
    fi

    IMAGE_URL=$(echo "''${RESPONSE}" | jq -r '.hdurl // .url')
    DATE_STR=$(date +%Y-%m-%d)
    WALLPAPER_FILE="''${WALLPAPER_DIR}/apod-''${DATE_STR}.jpg"

    if [ ! -f "''${WALLPAPER_FILE}" ]; then
      echo "nasa-apod-wallpaper: downloading ''${IMAGE_URL}"
      curl -s -L -o "''${WALLPAPER_FILE}" "''${IMAGE_URL}"
    fi

    if ! awww query > /dev/null 2>&1; then
      echo "nasa-apod-wallpaper: starting awww-daemon"
      awww-daemon &
      for _ in $(seq 1 10); do
        if awww query > /dev/null 2>&1; then
          break
        fi
        sleep 0.5
      done
    fi

    awww img "''${WALLPAPER_FILE}" \
      --transition-type any \
      --transition-duration 3 \
      --transition-fps 60

    echo "nasa-apod-wallpaper: set APOD ''${DATE_STR}"
  '';
in
{
  home.packages = [ nasaApodWallpaper ];

  # The service is triggered by the daily timer, by niri's spawn-at-startup
  # (initial set on login), and manually via the Mod+Shift+W keybind. It is
  # intentionally not wired to a *.target so it never runs before a Wayland
  # session exists (the script also guards on WAYLAND_DISPLAY).
  systemd.user.services.nasa-apod-wallpaper = {
    Unit = {
      Description = "Fetch and set NASA APOD wallpaper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${nasaApodWallpaper}/bin/nasa-apod-wallpaper";
    };
  };

  systemd.user.timers.nasa-apod-wallpaper = {
    Unit.Description = "Daily NASA APOD wallpaper refresh";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
