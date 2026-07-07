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

  # libvirt 12.x stores an encrypted credential at
  # /var/lib/libvirt/secrets/secrets-encryption-key, sealed by systemd-creds
  # against the host key /var/lib/systemd/credential.secret. virt-secret-init-
  # encryption.service only (re)creates it when missing (ConditionPathExists=!...).
  #
  # Under impermanence we persist all of /var/lib/libvirt (VM disks, nvram, swtpm
  # state) but NOT /var/lib/systemd/credential.secret — so the persisted blob ends
  # up sealed against a host key that the root-wipe destroys, and libvirtd fails on
  # every boot with status 243/CREDENTIALS ("Failed to determine local credential
  # key"). Rather than persist the host secret, we delete the blob on each boot
  # (r! = boot-only) so the init service regenerates it fresh against the current
  # boot's credential.secret. Safe here: there are no persistent `virsh secret`
  # objects, and the Win11 guest uses swtpm/OVMF nvram, not this key.
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/secrets 0700 root root -"
    "r! /var/lib/libvirt/secrets/secrets-encryption-key - - - - -"
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
