#!/usr/bin/env bash
# Enroll FIDO2 (YubiKey) fallback slots on cobalto's LUKS volumes.
#
# TPM2 is the primary and boots unattended; these FIDO2 slots are a fallback
# for when the TPM2 seal breaks (e.g. firmware/Secure Boot update).
#
# Run on cobalto (from the running OS) with a YubiKey in the first USB port.
# No screen needed. Each key must be enrolled once per volume (6 enrollments
# for 2 keys). Authorizes with the sops-decrypted LUKS passphrase.
#
# Usage:  sudo bash scripts/cobalto-luks-fido2-enroll.sh
set -euo pipefail

passphrase="${LUKS_PASSPHRASE_FILE:-/run/secrets/luks-passphrase}"
volumes=(
  "/dev/nvme0n1p2"   # cobalto-root
  "/dev/sdb1"        # cobalto-storage
  "/dev/sda1"        # cobalto-media
)

[[ -r "$passphrase" ]] || {
  echo "missing passphrase file: $passphrase (expected at /run/secrets/luks-passphrase)" >&2
  exit 1
}

enroll_key() {
  # $1 = human-readable key label
  read -r -p "Insert $1 and press Enter (or Ctrl-C to skip)... " _
  if ! systemd-cryptenroll --fido2-device=list | grep -q /dev; then
    echo "no FIDO2 device detected on this attempt" >&2
    return 1
  fi
  for dev in "${volumes[@]}"; do
    echo "== enrolling $1 -> $dev =="
    systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=no \
      --unlock-key-file="$passphrase" "$dev"
  done
}

echo "This will add FIDO2 slots to: ${volumes[*]}"
enroll_key "YubiKey A"
enroll_key "YubiKey B" || echo "key B not enrolled (skipped)"

echo
echo "Verifying FIDO2 keyslots:"
for dev in "${volumes[@]}"; do
  echo "== $dev =="
  cryptsetup luksDump "$dev" | grep -A 2 Tokens
done