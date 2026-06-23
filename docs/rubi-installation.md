# Installing NixOS on Rubi (Dual-Boot with Debian)

This guide covers installing the `rubi` NixOS host configuration on a system that dual-boots with Debian. The installation uses disko for declarative disk partitioning, LUKS encryption with TPM2/FIDO2 hardware-backed unlock, btrfs with impermanence, and COSMIC desktop.

## System Overview

| Component | Configuration |
|-----------|---------------|
| **Target Disk** | nvme1n1 (Kingston SNV2S1000G 1TB) - completely managed by NixOS |
| **Protected Disk** | nvme0n1 (Samsung, Debian) - never touched |
| **Desktop** | COSMIC (Wayland) with clipboard support |
| **Filesystem** | Btrfs with subvolumes (root, persist, nix, swap) |
| **Encryption** | LUKS with TPM2 + FIDO2 hardware-backed unlock |
| **Impermanence** | Root wiped on every boot, state persisted to `/nix/persist` |
| **Bootloader** | GRUB2 with graphical theme, dual-boot menu |

## Prerequisites

- NixOS live USB (unstable/25.05+)
- The target machine with:
  - nvme1n1: Target disk for NixOS (will be wiped)
  - nvme0n1: Debian installation (will be preserved)
- Your SOPS age key file (`key.txt`) - **bring this on a USB drive**
- (Optional) FIDO2 security key for hardware-backed LUKS unlock
- Internet connection

## Checklist: What to Bring/Prepare

Before starting installation, make sure you have:

- [ ] **NixOS Live USB** - bootable USB with NixOS ISO
- [ ] **USB drive with SOPS age key** - contains `key.txt` file
- [ ] **LUKS passphrase** - memorized or written down securely
- [ ] **WiFi password** (if not using ethernet)
- [ ] **Tailscale auth key** (optional) - from tailscale.com admin panel
- [ ] **secrets.yaml already encrypted** and committed to the repo (or ready to create)

## Required Secrets

You need to provide **3 secrets** in `hosts/rubi/secrets.yaml`:

| Secret | Description | How to Generate |
|--------|-------------|-----------------|
| `luks-passphrase` | LUKS disk encryption password | Choose a strong passphrase |
| `diego-password` | User login password (hashed) | `mkpasswd -m sha-512` |
| `tailscale-key` | Tailscale auth key (optional but recommended) | [tailscale.com/admin/settings/keys](https://tailscale.com/admin/settings/keys) - create reusable key |

## SOPS Age Key

Your SOPS age key (`key.txt`) is required to decrypt secrets during installation. 

### Where to Get It

The key is the same one used for cobalto/other hosts. It's stored at:
- On cobalto: `/nix/persist/var/lib/sops-nix/key.txt`
- Backup location: wherever you keep secure backups

### How to Bring It to Installation

**Option A: USB Drive (Recommended)**
1. Copy `key.txt` to a USB drive before installation
2. During installation, mount the USB and copy to the target

**Option B: Secure Paste**
1. Have the key content available (e.g., password manager)
2. Paste it directly during installation

The key looks like:
```
# created: 2024-XX-XX
# public key: age1ka44gzmhvrgaxn5pm9eml0k4srh5rjxr87dtrtn4exmwcxz2yeusjrmdne
AGE-SECRET-KEY-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Pre-Installation Steps

### 1. Prepare Secrets (Do This Before Booting Live USB)

On your current system (or any system with sops installed), create and encrypt the secrets file:

```bash
cd hosts/rubi

# Copy the template
cp secrets.yaml.template secrets.yaml

# Edit with your actual values:
# - luks-passphrase: Your LUKS encryption passphrase
# - tailscale-key: Reusable auth key from tailscale.com/admin/settings/keys
# - diego-password: Generate with: mkpasswd -m sha-512
nano secrets.yaml

# Encrypt the file (requires your age key)
sops -e -i secrets.yaml

# Verify it's encrypted
head secrets.yaml  # Should show encrypted values
```

### 2. Verify Disk Layout

**CRITICAL**: Confirm which disk is which before proceeding!

```bash
lsblk -f
# nvme0n1 should be your Debian disk (Samsung) - DO NOT TOUCH
# nvme1n1 should be the target disk (Kingston) - will be WIPED
```

## Installation

### 1. Boot NixOS Live Environment

Boot from a NixOS live USB. Use the unstable or 25.05+ ISO for COSMIC support.

### 2. Connect to Network

```bash
# For WiFi
nmcli device wifi connect "SSID" password "PASSWORD"

# Or use ethernet (usually auto-configured)
```

### 3. Clone the Configuration

```bash
nix-shell -p git

git clone https://github.com/DiegoBarrosA/nix-config.git
cd nix-config
```

### 4. Prepare LUKS Passphrase

Create a temporary file with your LUKS passphrase (used by disko):

```bash
echo "YOUR_LUKS_PASSPHRASE" > /tmp/luks-passphrase
chmod 600 /tmp/luks-passphrase
```

### 5. Run Disko (Partition & Format)

**WARNING**: This will completely erase nvme1n1!

```bash
# Verify the target disk one more time
lsblk /dev/nvme1n1

# Run disko to partition and format
sudo nix run github:nix-community/disko -- \
  --mode disko \
  --flake .#rubi
```

This will:
- Create GPT partition table on nvme1n1
- Create 1GB EFI partition (nvme1n1p1)
- Create LUKS-encrypted root partition (nvme1n1p2)
- Format with btrfs and create subvolumes (root, root-blank, persist, nix, swap)
- Mount everything under `/mnt`

### 6. Copy SOPS Age Key

The age key is **required** for secrets decryption. Without it, the system won't have your user password or Tailscale key.

```bash
# Create the directory structure
sudo mkdir -p /mnt/nix/persist/var/lib/sops-nix

# Option A: From USB drive (recommended)
# First, find and mount your USB with the key
lsblk  # Find your USB (e.g., /dev/sda1)
sudo mkdir -p /mnt/usb
sudo mount /dev/sda1 /mnt/usb
sudo cp /mnt/usb/key.txt /mnt/nix/persist/var/lib/sops-nix/key.txt

# Option B: Paste directly (if you have the key content)
sudo tee /mnt/nix/persist/var/lib/sops-nix/key.txt << 'EOF'
# created: 2024-XX-XX
# public key: age1ka44gzmhvrgaxn5pm9eml0k4srh5rjxr87dtrtn4exmwcxz2yeusjrmdne
AGE-SECRET-KEY-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EOF

# Set correct permissions (IMPORTANT!)
sudo chmod 600 /mnt/nix/persist/var/lib/sops-nix/key.txt
sudo chown root:root /mnt/nix/persist/var/lib/sops-nix/key.txt

# Verify the key is in place
sudo cat /mnt/nix/persist/var/lib/sops-nix/key.txt | head -3
```

### 7. Install NixOS

```bash
sudo nixos-install --flake .#rubi --no-root-passwd
```

The `--no-root-passwd` flag is used because the user password is managed via SOPS secrets.

### 8. Reboot

```bash
sudo reboot
```

Remove the USB drive when prompted.

## Post-Installation

### 1. First Boot

On first boot:
- GRUB will show a menu with NixOS and Debian options (10 second timeout)
- You'll be prompted for the LUKS passphrase
- COSMIC greeter will appear for login

### 2. Enroll TPM2 for Automatic Unlock (Optional)

To enable automatic LUKS unlock using TPM2:

```bash
# Enroll TPM2
sudo systemd-cryptenroll /dev/nvme1n1p2 --tpm2-device=auto --tpm2-pcrs=0+7

# Test by rebooting - should unlock automatically
```

### 3. Enroll FIDO2 Key (Optional)

To add FIDO2 security key as unlock method:

```bash
# Enroll FIDO2 key
sudo systemd-cryptenroll /dev/nvme1n1p2 --fido2-device=auto

# List enrolled methods
sudo systemd-cryptenroll /dev/nvme1n1p2
```

### 4. Verify Impermanence

After reboot, verify impermanence is working:

```bash
# Root should be clean (only NixOS-generated files)
ls -la /

# Persistent data should be in /nix/persist
ls /nix/persist/home/diego
ls /nix/persist/etc/ssh
```

### 5. Setup Home Manager

```bash
home-manager switch --flake .#diego@rubi
```

## Troubleshooting

### GRUB Doesn't Show Debian

If Debian isn't detected, manually add it:

1. Find Debian's EFI partition UUID:
   ```bash
   sudo blkid /dev/nvme0n1p1
   ```

2. Edit `/boot/grub/grub.cfg` or update `hosts/rubi/bootloader.nix` with correct UUID

3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#rubi
   ```

### LUKS Unlock Fails

If TPM2/FIDO2 unlock fails:

```bash
# Boot with passphrase fallback (always available)
# Then re-enroll TPM2/FIDO2

# Remove existing enrollment
sudo systemd-cryptenroll /dev/nvme1n1p2 --wipe-slot=tpm2

# Re-enroll
sudo systemd-cryptenroll /dev/nvme1n1p2 --tpm2-device=auto --tpm2-pcrs=0+7
```

### COSMIC Issues

If COSMIC doesn't start properly:

```bash
# Check logs
journalctl -b -u cosmic-greeter
journalctl -b --user -u cosmic-session

# Verify Wayland is working
echo $XDG_SESSION_TYPE  # Should be "wayland"
```

### Impermanence Issues

To temporarily disable root wipe (for debugging):

```bash
sudo touch /nix/persist/dont-wipe
sudo reboot
```

Remove the file to re-enable impermanence.

## Maintenance

### Updating the System

```bash
cd ~/nix-config
git pull
sudo nixos-rebuild switch --flake .#rubi
```

### Updating Flake Inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#rubi
```

### Backup Considerations

With impermanence, critical data is in `/nix/persist`. Back up:
- `/nix/persist/home/diego` - User data
- `/nix/persist/etc/ssh` - SSH host keys
- `/nix/persist/var/lib/sops-nix/key.txt` - Age key (keep secure!)

## File Structure

```
hosts/rubi/
├── default.nix              # Main host configuration
├── hardware-configuration.nix # Disko disk layout
├── impermanence.nix         # Persistence configuration
├── bootloader.nix           # GRUB dual-boot setup
├── sops.nix                 # Secrets configuration
├── .sops.yaml               # SOPS encryption rules
├── secrets.yaml             # Encrypted secrets (not in git template)
└── secrets.yaml.template    # Template for secrets
```
