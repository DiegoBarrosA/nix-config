{ pkgs, ... }: {
  services = {
    usbmuxd.enable = true;
    gvfs.enable = true;
    devmon.enable = true;
    udev.packages = [ pkgs.android-udev-rules pkgs.logitech-udev-rules ];
  };
  environment.systemPackages = with pkgs; [
    sshfs
    libimobiledevice
    ifuse
    exfatprogs
    ntfs3g
    mtpfs
    android-tools
  ];

}
