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
    OVMF
  ];
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1
  '';
  environment.variables = { LIBVIRT_DEFAULT_URI = "qemu:///system"; };
  virtualisation.libvirtd.qemu.verbatimConfig = ''
        nvram = [
    "/nix/store/mz1mbkhwjw6wqz2jvpqna4jchxrkmzl1-OVMF-202205-fd/FV/OVMF.fd"

        ]
  '';

}
