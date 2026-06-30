{ config, lib, pkgs, ... }:

let
  nasaWallpaper = pkgs.writeShellScriptBin "nasa-apod-wallpaper" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [
      pkgs.curl
      pkgs.jq
      pkgs.awww
      pkgs.swaybg
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
      pkgs.imagemagick
      pkgs.procps
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

    echo "nasa-wallpaper: searching for ''${TOPIC}"
    SEARCH=$(curl -s -f \
      "https://images-api.nasa.gov/search?q=''${QUERY}&media_type=image&page_size=100") || {
      echo "nasa-wallpaper: search request failed (no network?)"
      exit 0
    }

    # Collect nasa_id values, but drop items whose metadata (title +
    # keywords + description) suggests people/portraits/ceremonies. NASA's
    # tagging is sparse, so this is best-effort: combined with space-only
    # search topics it filters out the obvious astronaut/crew/event shots.
    PEOPLE_RE="astronaut|cosmonaut|crew|portrait|headshot|ceremony|administrator|official|employee|staff|press|conference|briefing|award|graduat|training|spacewalk|interview|visit|signing|meeting|team photo|group photo|posing|smiling|holds|holding|speaks|speaking|address|panel|audience|expedition .* crew"
    mapfile -t IDS < <(printf '%s' "''${SEARCH}" | jq -r --arg re "''${PEOPLE_RE}" '
      .collection.items[]
      | .data[0]
      | ([.title, (.keywords // [] | join(" ")), .description] | join(" ") | ascii_downcase) as $text
      | select($text | test($re) | not)
      | .nasa_id
    ' 2>/dev/null)
    if [ "''${#IDS[@]}" -eq 0 ]; then
      echo "nasa-wallpaper: no people-free results for ''${TOPIC}, skipping"
      exit 0
    fi

    # Minimum width (px) to consider an image worthy of a wallpaper. Some
    # NASA "~orig" archives are tiny, so we measure each candidate and skip
    # anything too small to fill the screen without heavy upscaling.
    MIN_WIDTH=1920

    # Try up to 12 random items until we find a sufficiently large original.
    WALLPAPER_FILE=""
    NASA_ID=""
    for _ in $(seq 1 12); do
      CANDIDATE="''${IDS[$((RANDOM % ''${#IDS[@]}))]}"
      ASSETS=$(curl -s -f \
        "https://images-api.nasa.gov/asset/''${CANDIDATE}") || continue
      URL=$(printf '%s' "''${ASSETS}" \
        | jq -r '.collection.items[].href' 2>/dev/null \
        | grep -iE '~orig\.(jpg|jpeg|png)$' \
        | head -n1 || true)
      [ -n "''${URL}" ] || continue
      URL="''${URL/http:/https:}"

      EXT="''${URL##*.}"
      TMP_FILE="''${WALLPAPER_DIR}/nasa-''${CANDIDATE}.''${EXT}"
      if [ ! -f "''${TMP_FILE}" ]; then
        curl -s -f -L -o "''${TMP_FILE}" "''${URL}" || { rm -f "''${TMP_FILE}"; continue; }
      fi

      WIDTH=$(identify -format '%w' "''${TMP_FILE}" 2>/dev/null || echo 0)
      if [ "''${WIDTH}" -ge "''${MIN_WIDTH}" ]; then
        WALLPAPER_FILE="''${TMP_FILE}"
        NASA_ID="''${CANDIDATE}"
        echo "nasa-wallpaper: selected ''${CANDIDATE} (''${WIDTH}px wide)"
        break
      else
        echo "nasa-wallpaper: ''${CANDIDATE} too small (''${WIDTH}px), trying another"
        rm -f "''${TMP_FILE}"
      fi
    done

    if [ -z "''${WALLPAPER_FILE}" ]; then
      echo "nasa-wallpaper: no sufficiently large image found, skipping"
      exit 0
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

    # awww is placed within niri's overview backdrop (see the layer-rule in
    # the niri config), which removes it from the per-workspace background.
    # Run swaybg with the same image so the wallpaper also shows on the
    # active workspace, not just in the overview.
    pkill -x swaybg > /dev/null 2>&1 || true
    setsid -f swaybg -i "''${WALLPAPER_FILE}" -m fill > /dev/null 2>&1 \
      || swaybg -i "''${WALLPAPER_FILE}" -m fill &

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
