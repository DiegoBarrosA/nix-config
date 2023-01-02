{ config, pkgs, ... }: {
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-vdagent
    spice-protocol
    win-virtio
    win-spice
  ];
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1
  '';
  environment.variables = { LIBVIRT_DEFAULT_URI = "qemu:///system"; };
}
