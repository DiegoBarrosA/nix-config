{ lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  usbutils,
  libimobiledevice,
  ifuse,
  go-mtpfs,
  libmtp,
  fuse3,
  util-linux
}:
let
  device-mount = writeShellApplication {
    name = "device-mount";
    runtimeInputs = [
      coreutils
      gnugrep
      usbutils
      libimobiledevice
      ifuse
      go-mtpfs
      libmtp
      fuse3
      util-linux
    ];
    text = ''
      set -euo pipefail

      MNT_ROOT=''${DEVICE_MNT_ROOT:-"$HOME/mnt"}
      LSUSB=${usbutils}/bin/lsusb
      MOUNTPOINT=${util-linux}/bin/mountpoint
      UMOUNT=${util-linux}/bin/umount
      IDEVICEPAIR=${libimobiledevice}/bin/idevicepair
      IFUSE=${ifuse}/bin/ifuse
      GO_MTPFS=${go-mtpfs}/bin/go-mtpfs
      MTP_DETECT=${libmtp}/bin/mtp-detect
      if [ -x /run/wrappers/bin/fusermount3 ]; then
        FUSERMOUNT=/run/wrappers/bin/fusermount3
      elif [ -x ${fuse3}/bin/fusermount3 ]; then
        FUSERMOUNT=${fuse3}/bin/fusermount3
      else
        FUSERMOUNT=fusermount3
      fi

      # Apple iPhone/iPad/iPod in normal (non-recovery) USB mode
      APPLE_PRODUCTS="12a8 12ab"

      # Common Android vendor IDs (mirrors hosts/common/optional/desktop/devices.nix)
      ADB_VENDORS="18d1 0bb4 04e8 22b8 1004 413c 091e 12d1 8087 05c6 2717 2e17 109b 2b4c 1d6b 1f53"

      have_iphone() {
        local id
        id=$("$LSUSB" -d 05ac: 2>/dev/null | grep -oiE "05ac:[0-9a-f]+" | head -1)
        [ -n "$id" ] || return 1
        local prod
        prod=''${id##*:}
        local p
        for p in $APPLE_PRODUCTS; do
          [ "$p" = "$prod" ] && return 0
        done
        return 1
      }

      have_mtp() {
        local v
        for v in $ADB_VENDORS; do
          "$LSUSB" -d "$v": 2>/dev/null | grep -q . && return 0
        done
        return 1
      }

      ensure_dir() {
        mkdir -p "$1"
      }

      # Wait up to ~30s for the owner to accept the Trust dialog and for
      # pairing to complete. Re-pairs on every attempt.
      wait_paired() {
        local _
        for _ in {1..15}; do
          "$IDEVICEPAIR" pair >/dev/null 2>&1 || true
          if "$IDEVICEPAIR" validate >/dev/null 2>&1; then
            return 0
          fi
          sleep 2
        done
        return 1
      }

      # Wait up to ~30s for an MTP device to show up and settle.
      wait_mtp() {
        local _
        for _ in {1..15}; do
          if "$MTP_DETECT" 2>&1 | grep -q "Found [1-9]"; then
            return 0
          fi
          sleep 2
        done
        return 1
      }

      clean_stale_mount() {
        local target="$1"
        # mountpoint -q succeeds only for healthy FUSE mounts.
        if "$MOUNTPOINT" -q "$target" 2>/dev/null; then
          return 0
        fi
        # findmnt sees ghost mounts left behind after the process died.
        if findmnt "$target" >/dev/null 2>&1; then
          "$FUSERMOUNT" -u "$target" 2>/dev/null || "$UMOUNT" -l "$target" 2>/dev/null || true
          rmdir "$target" 2>/dev/null || true
        fi
        return 1
      }

      mount_iphone() {
        local target="''${1:-$MNT_ROOT/iphone}"
        if clean_stale_mount "$target"; then
          echo "iPhone already mounted at $target"
          return 0
        fi
        ensure_dir "$target"
        have_iphone || {
          echo "No iPhone detected." >&2
          exit 1
        }
        if ! wait_paired; then
          echo "Could not pair with iPhone. Unlock it and accept the Trust dialog, then run: device-mount iphone" >&2
          exit 1
        fi
        "$IFUSE" "$target"
        echo "iPhone mounted at $target"
      }

      mount_mtp() {
        local target="''${1:-$MNT_ROOT/droid}"
        if clean_stale_mount "$target"; then
          echo "Device already mounted at $target"
          return 0
        fi
        ensure_dir "$target"
        have_mtp || {
          echo "No MTP device detected." >&2
          exit 1
        }
        if ! wait_mtp; then
          echo "No MTP device available. Set the phone to 'File transfer' (MTP) mode." >&2
          exit 1
        fi
        "$GO_MTPFS" "$target" >/dev/null 2>&1 &
        local _
        for _ in {1..10}; do
          if "$MOUNTPOINT" -q "$target" 2>/dev/null; then
            echo "Device mounted at $target"
            return 0
          fi
          sleep 1
        done
        echo "go-mtpfs did not mount $target" >&2
        exit 1
      }

      unmount_iphone() {
        local target="''${1:-$MNT_ROOT/iphone}"
        if ! "$MOUNTPOINT" -q "$target" 2>/dev/null; then
          # Stale mount (device gone): try to clear it anyway.
          if [ -d "$target" ] && findmnt -n "$target" >/dev/null 2>&1; then
            "$FUSERMOUNT" -u "$target" 2>/dev/null || true
          fi
          echo "iPhone not mounted at $target"
          return 0
        fi
        "$FUSERMOUNT" -u "$target" 2>/dev/null || "$UMOUNT" "$target"
        echo "iPhone unmounted: $target"
      }

      unmount_mtp() {
        local target="''${1:-$MNT_ROOT/droid}"
        if ! "$MOUNTPOINT" -q "$target" 2>/dev/null; then
          echo "Device not mounted at $target"
          return 0
        fi
        "$FUSERMOUNT" -u "$target" 2>/dev/null || "$UMOUNT" "$target"
        echo "Device unmounted: $target"
      }

      list_mounts() {
        echo "Custom mounts under $MNT_ROOT:"
        local d mounted=0
        for d in "$MNT_ROOT"/*; do
          [ -d "$d" ] || continue
          if "$MOUNTPOINT" -q "$d" 2>/dev/null; then
            echo "  mounted: $d"
            mounted=1
          fi
        done
        [ "$mounted" = 0 ] && echo "  (none)"
        echo
        echo "udiskie mounts under /run/media/$USER:"
        local stick sticks=0
        for stick in /run/media/"$USER"/*; do
          [ -e "$stick" ] && { echo "  $stick"; sticks=1; }
        done
        [ "$sticks" = 0 ] && echo "  (none)"
      }

      case "''${1:-all}" in
        all)
          if have_iphone; then
            mount_iphone
          elif have_mtp; then
            mount_mtp
          else
            echo "No removable device detected. Plug one in first." >&2
            exit 1
          fi
          ;;
        iphone|ios)
          mount_iphone "''${2:-}"
          ;;
        umount-iphone|umount-ios)
          unmount_iphone "''${2:-}"
          ;;
        android|mtp|droid)
          mount_mtp "''${2:-}"
          ;;
        umount-mtp|umount-android|umount-droid)
          unmount_mtp "''${2:-}"
          ;;
        umount|u)
          if "$MOUNTPOINT" -q "$MNT_ROOT/iphone" 2>/dev/null; then
            unmount_iphone
          else
            unmount_mtp
          fi
          ;;
        list|ls|status)
          list_mounts
          ;;
        mountpoint)
          if have_iphone; then
            echo "$MNT_ROOT/iphone"
          elif have_mtp; then
            echo "$MNT_ROOT/droid"
          fi
          ;;
        *)
          echo "Usage: device-mount [all|iphone|android|umount|list|mountpoint] [DEST]" >&2
          exit 1
          ;;
      esac
    '';
  };

  device-umount = writeShellApplication {
    name = "device-umount";
    runtimeInputs = [ device-mount ];
    text = ''
      exec device-mount umount "$@"
    '';
  };
in
{
  inherit device-mount device-umount;
}