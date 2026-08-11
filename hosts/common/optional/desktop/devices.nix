{ pkgs, ... }: {
  services = {
    usbmuxd.enable = true;
    gvfs.enable = true;
    devmon.enable = true;
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
  users.groups.adbusers = { };
  services.udev.extraRules = ''
    # Android Developer USB devices (ADB protocol)
    # Grants the adbusers group rw access to any USB device with Android ADB interface
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="413c", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="091e", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2e17", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="109b", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2b4c", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d6b", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1f53", MODE="0664", GROUP="adbusers"
    # Fastboot mode
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="d00d", MODE="0664", GROUP="adbusers"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="d001", MODE="0664", GROUP="adbusers"
  '';
}
