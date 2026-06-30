{ config, lib, pkgs, ... }:

let
  nasaWallpaper = pkgs.writeShellScriptBin "nasa-apod-wallpaper" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [
      pkgs.curl
      pkgs.jq
      pkgs.awww
      pkgs.coreutils
      pkgs.gnused
      pkgs.util-linux
    ]}

    # Need a Wayland session to set a wallpaper; bail quietly otherwise.
    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      echo "nasa-wallpaper: no WAYLAND_DISPLAY, skipping"
      exit 0
    fi

    WALLPAPER_DIR="''${HOME}/.wallpapers"
    mkdir -p "''${WALLPAPER_DIR}"

    # Source: NASA Image and Video Library (images.nasa.gov).
    # Keyless API, and every item exposes a full-resolution "~orig.jpg",
    # so we always get genuinely high-quality wallpapers (no APOD daily
    # resolution lottery, no DEMO_KEY rate limits).
    TOPICS=(
      "nebula" "galaxy" "hubble" "james webb" "supernova"
      "star cluster" "spiral galaxy" "earth from space" "aurora"
      "saturn" "jupiter" "mars surface" "deep field" "milky way"
    )
    TOPIC="''${TOPICS[$((RANDOM % ''${#TOPICS[@]}))]}"
    QUERY=$(printf '%s' "''${TOPIC}" | jq -sRr @uri)

    echo "nasa-wallpaper: searching for '''${TOPIC}'"
    SEARCH=$(curl -s -f \
      "https://images-api.nasa.gov/search?q=''${QUERY}&media_type=image&page_size=100") || {
      echo "nasa-wallpaper: search request failed (no network?)"
      exit 0
    }

    # Collect all nasa_id values, pick one at random.
    mapfile -t IDS < <(printf '%s' "''${SEARCH}" \
      | jq -r '.collection.items[].data[0].nasa_id' 2>/dev/null)
    if [ "''${#IDS[@]}" -eq 0 ]; then
      echo "nasa-wallpaper: no results for '''${TOPIC}', skipping"
      exit 0
    fi

    # Try up to 8 random items until we find a usable high-res original.
    IMAGE_URL=""
    NASA_ID=""
    for _ in $(seq 1 8); do
      CANDIDATE="''${IDS[$((RANDOM % ''${#IDS[@]}))]}"
      ASSETS=$(curl -s -f \
        "https://images-api.nasa.gov/asset/''${CANDIDATE}") || continue
      URL=$(printf '%s' "''${ASSETS}" \
        | jq -r '.collection.items[].href' 2>/dev/null \
        | grep -iE '~orig\.(jpg|jpeg|png)$' \
        | head -n1 || true)
      if [ -n "''${URL}" ]; then
        IMAGE_URL="''${URL/http:/https:}"
        NASA_ID="''${CANDIDATE}"
        break
      fi
    done

    if [ -z "''${IMAGE_URL}" ]; then
      echo "nasa-wallpaper: could not find a high-res original, skipping"
      exit 0
    fi

    EXT="''${IMAGE_URL##*.}"
    WALLPAPER_FILE="''${WALLPAPER_DIR}/nasa-''${NASA_ID}.''${EXT}"

    if [ ! -f "''${WALLPAPER_FILE}" ]; then
      echo "nasa-wallpaper: downloading ''${IMAGE_URL}"
      curl -s -f -L -o "''${WALLPAPER_FILE}" "''${IMAGE_URL}" || {
        echo "nasa-wallpaper: download failed, skipping"
        rm -f "''${WALLPAPER_FILE}"
        exit 0
      }
    fi

    if ! awww query > /dev/null 2>&1; then
      echo "nasa-wallpaper: starting awww-daemon"
      setsid -f awww-daemon > /dev/null 2>&1 || awww-daemon &
      for _ in $(seq 1 10); do
        if awww query > /dev/null 2>&1; then
          break
        fi
        sleep 0.5
      done
    fi

    awww img "''${WALLPAPER_FILE}" \
      --resize crop \
      --fill-color "000000" \
      --transition-type any \
      --transition-duration 3 \
      --transition-fps 60

    echo "nasa-wallpaper: set ''${NASA_ID} (''${TOPIC})"
  '';
in
{
  home.packages = [ nasaWallpaper ];

  # The service is triggered by the daily timer, by niri's spawn-at-startup
  # (initial set on login), and manually via the Mod+Shift+W keybind. It is
  # intentionally not wired to a *.target so it never runs before a Wayland
  # session exists (the script also guards on WAYLAND_DISPLAY).
  systemd.user.services.nasa-apod-wallpaper = {
    Unit = {
      Description = "Fetch and set a NASA wallpaper";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${nasaWallpaper}/bin/nasa-apod-wallpaper";
    };
  };

  systemd.user.timers.nasa-apod-wallpaper = {
    Unit.Description = "Daily NASA wallpaper refresh";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
