{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/secrets 0700 root root -"
    "r! /var/lib/libvirt/secrets/secrets-encryption-key - - - - -"
  ];
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice-gtk
    virtio-win
    swtpm
  ];
}
