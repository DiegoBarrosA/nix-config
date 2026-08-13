#!/usr/bin/env bash
# Deploy the nix-on-droid (Infinix phone) config to the phone over adb.
#
# Builds a minimal snapshot of the repo (only what the infinix flake eval
# needs; no secrets, no desktop configs), pushes it to
# /sdcard/Download/phone/, and writes the on-device switch script to
# /sdcard/Download/switch-infinix.sh.
#
# After this, run on the phone inside the nix-on-droid app:
#   bash /sdcard/Download/switch-infinix.sh
#
# Output: /sdcard/Download/switch.log (heartbeat in switch_hb.txt).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
phone_dir="/sdcard/Download/phone"
tar_name="nix-config.tar.gz"
tmp_tar="$(mktemp /tmp/phone-nix-config.XXXXXX.tar.gz)"
trap 'rm -f "$tmp_tar"' EXIT

cd "$repo"

# Keep in sync with what the infinix eval actually forces (see lib/default.nix
# -> mkNixOnDroid): the flake root + lock, lib, hosts/infinix, the shared
# global + cli modules, and the colorscheme module.
tar czf "$tmp_tar" \
  flake.nix \
  flake.lock \
  lib/default.nix \
  hosts/infinix/nix-on-droid.nix \
  home/diego/global/default.nix \
  home/diego/features/cli/ \
  modules/home-manager/colors.nix \
  modules/home-manager/colorschemes/

adb shell "mkdir -p $phone_dir"
adb push "$tmp_tar" "$phone_dir/$tar_name"

# Write the on-device switch script (stays on the phone; re-run this to update
# it). Uses a quoted heredoc so $HOME etc. are NOT expanded here.
adb shell "cat > /sdcard/Download/switch-infinix.sh" <<'EOF'
set -e
rm -rf $HOME/nix-config
mkdir -p $HOME/nix-config
tar -xzf /sdcard/Download/phone/nix-config.tar.gz -C $HOME/nix-config
cd $HOME/nix-config
(
  while true; do echo "HB $(date +%H:%M:%S)" >> /sdcard/Download/switch_hb.txt; sleep 30; done
) &
HB=$!
echo "=== starting switch $(date) ===" > /sdcard/Download/switch.log
nix-on-droid switch --flake .#infinix >> /sdcard/Download/switch.log 2>&1
echo "SWITCH_EXIT=$?" >> /sdcard/Download/switch.log
kill $HB 2>/dev/null
echo SWITCH_SCRIPT_DONE
EOF
adb shell "chmod 755 /sdcard/Download/switch-infinix.sh"

echo "Deployed $(tar -tzf "$tmp_tar" | wc -l | tr -d ' ') files to $phone_dir/$tar_name"
echo
echo "On the phone (nix-on-droid app), run:"
echo "  bash /sdcard/Download/switch-infinix.sh"
