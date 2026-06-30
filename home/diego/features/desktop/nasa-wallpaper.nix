{ config, lib, pkgs, ... }:

let
  nasaWallpaper = pkgs.writeShellScriptBin "nasa-apod-wallpaper" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [
      pkgs.curl
      pkgs.awww
      pkgs.swaybg
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
      pkgs.findutils
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
    POOL_DIR="''${WALLPAPER_DIR}/nasa-iss"
    mkdir -p "''${POOL_DIR}"

    # Source: NASA's monthly ISS "Desktop and Mobile Wallpapers" page.
    # We grab the full-resolution desktop "image only" PNGs (no calendar
    # overlay), maintain a local pool, and rotate through it.
    PAGE="https://www.nasa.gov/international-space-station/desktop-and-mobile-wallpapers/"

    # Refresh the pool: scrape desktop image-only URLs and download new ones.
    # Failures here are non-fatal — we can still rotate the existing pool.
    if PAGE_HTML=$(curl -s -f "''${PAGE}" 2>/dev/null); then
      printf '%s' "''${PAGE_HTML}" \
        | grep -oE 'https://www\.nasa\.gov/wp-content/uploads/[^"'"'"' ]*desktop[^"'"'"' ]*image-only\.png' \
        | sort -u \
        | while read -r url; do
            # Stable local filename from the URL basename (decode %20 etc.).
            base=$(basename "''${url}" | sed 's/%[0-9A-Fa-f][0-9A-Fa-f]/-/g')
            dest="''${POOL_DIR}/''${base}"
            if [ ! -f "''${dest}" ]; then
              echo "nasa-wallpaper: downloading ''${base}"
              curl -s -f -L -o "''${dest}" "''${url}" || rm -f "''${dest}"
            fi
          done
    else
      echo "nasa-wallpaper: could not reach NASA page (no network?), using existing pool"
    fi

    # Pick a random image from the pool.
    mapfile -t POOL < <(find "''${POOL_DIR}" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) 2>/dev/null | sort)
    if [ "''${#POOL[@]}" -eq 0 ]; then
      echo "nasa-wallpaper: wallpaper pool is empty, skipping"
      exit 0
    fi
    WALLPAPER_FILE="''${POOL[$((RANDOM % ''${#POOL[@]}))]}"
    echo "nasa-wallpaper: selected $(basename "''${WALLPAPER_FILE}")"

    # Build a blurred copy for the overview backdrop. awww is placed within
    # niri's overview backdrop (see the layer-rule in the niri config), so
    # feeding it the blurred image yields a blurred overview while swaybg
    # shows the sharp image on the active workspace.
    BLUR_FILE="''${WALLPAPER_DIR}/.current-blur.jpg"
    if ! convert "''${WALLPAPER_FILE}" -resize 1920x -blur 0x20 -quality 90 "''${BLUR_FILE}" 2>/dev/null; then
      echo "nasa-wallpaper: blur failed, falling back to sharp image in overview"
      BLUR_FILE="''${WALLPAPER_FILE}"
    fi

    # --- Overview backdrop (awww, blurred) ---
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

    awww img "''${BLUR_FILE}" \
      --resize crop \
      --fill-color "000000" \
      --transition-type any \
      --transition-duration 3 \
      --transition-fps 60

    # --- Active workspace background (swaybg, sharp) ---
    # Launch the new swaybg first, then cleanly retire any previous ones so
    # there is no flicker and no orphaned background surfaces.
    OLD_SWAYBG=$(pgrep -x swaybg 2>/dev/null || true)
    setsid -f swaybg -i "''${WALLPAPER_FILE}" -m fill > /dev/null 2>&1 \
      || swaybg -i "''${WALLPAPER_FILE}" -m fill &
    sleep 1
    if [ -n "''${OLD_SWAYBG}" ]; then
      # SIGTERM lets swaybg destroy its layer surface cleanly.
      kill -TERM ''${OLD_SWAYBG} > /dev/null 2>&1 || true
    fi

    # Retention: NASA publishes ~3 new wallpapers/month, so the pool grows
    # slowly. Cap it at the 60 most-recently-downloaded images so it never
    # grows unbounded over years, while keeping plenty of variety.
    find "''${POOL_DIR}" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) -printf '%T@ %p\n' 2>/dev/null \
      | sort -rn \
      | tail -n +61 \
      | cut -d' ' -f2- \
      | while read -r old; do
          [ "''${old}" = "''${WALLPAPER_FILE}" ] && continue
          rm -f "''${old}"
        done

    echo "nasa-wallpaper: set $(basename "''${WALLPAPER_FILE}")"
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
