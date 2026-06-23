# Virtualization module: libvirtd + virt-manager for KVM/QEMU VMs
# Configured for Windows 11 support (UEFI + TPM 2.0 + virtio-gpu)
{ config, lib, pkgs, ... }:

{
  # libvirtd with QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;  # TPM 2.0 emulation for Win11
      # Note: OVMF is now available by default in NixOS unstable
      # The ovmf submodule was removed - all OVMF images are distributed with QEMU
    };
  };

  # USB redirection for VMs
  virtualisation.spiceUSBRedirection.enable = true;

  # Ensure the secrets directory exists before virt-secret-init-encryption.service runs.
  # libvirt 12.x requires a LoadCredentialEncrypted key at /var/lib/libvirt/secrets/
  # secrets-encryption-key; the init service creates it but only if the directory exists.
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/secrets 0700 root root -"
  ];

  # dconf for virt-manager GUI settings persistence (required under Wayland/Sway)
  programs.dconf.enable = true;

  # VM management packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice-gtk
    virtio-win      # virtio-win drivers ISO for Windows guests
    swtpm
  ];
}
