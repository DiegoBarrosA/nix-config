# Bootloader configuration for rubi
# Uses systemd-boot for faster boot (no GRUB filesystem drivers, native UEFI)
# Debian is on nvme0n1 (Samsung) - chainloaded via extraEntries
{ pkgs, ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      editor = false; # Security: prevent kernel param editing at boot
      graceful = true; # Don't hard fail if EFI vars unavailable

      # Limit generations shown in boot menu
      configurationLimit = 10;

      # Sign systemd-boot EFI stub and all kernels after installation (Secure Boot)
      extraInstallCommands = ''
        ${pkgs.sbctl}/bin/sbctl sign /boot/EFI/systemd/systemd-bootx64.efi --save || true
        for kernel in /boot/EFI/nixos/*bzImage.efi; do
          [ -e "$kernel" ] || continue
          ${pkgs.sbctl}/bin/sbctl sign "$kernel" --save || true
        done
      '';
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    timeout = 0; # Instant boot, hold Space at POST to show menu
  };
}
