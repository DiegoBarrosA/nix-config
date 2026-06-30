{ config, lib, pkgs, ... }:

let
  nasaApodWallpaper = pkgs.writeShellScript "nasa-apod-wallpaper" ''
    set -euo pipefail

    WALLPAPER_DIR="''${HOME}/.wallpapers"
    API_KEY="''${NASA_API_KEY:-DEMO_KEY}"
    API_URL="https://api.nasa.gov/planetary/apod?api_key=''${API_KEY}"

    mkdir -p "''${WALLPAPER_DIR}"

    RESPONSE=$(curl -s -f "''${API_URL}") || {
      echo "nasa-apod-wallpaper: failed to fetch APOD (no network? rate limit?)"
      exit 0
    }

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

    if ! ${pkgs.awww}/bin/awww query > /dev/null 2>&1; then
      echo "nasa-apod-wallpaper: starting awww-daemon"
      ${pkgs.awww}/bin/awww-daemon &
      for _ in $(seq 1 10); do
        if ${pkgs.awww}/bin/awww query > /dev/null 2>&1; then
          break
        fi
        sleep 0.5
      done
    fi

    ${pkgs.awww}/bin/awww img "''${WALLPAPER_FILE}" \
      --transition-type any \
      --transition-duration 3 \
      --transition-fps 60

    echo "nasa-apod-wallpaper: set APOD ''${DATE_STR}"
  '';
in
{
  home.packages = [ nasaApodWallpaper ];

  systemd.user.services.nasa-apod-wallpaper = {
    Unit = {
      Description = "Fetch and set NASA APOD wallpaper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${nasaApodWallpaper}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.nasa-apod-wallpaper = {
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
