{ pkgs, lib, config, ... }:
let
  cfg = config.automount;
in
{
  options.automount = {
    blacklistAppleNet = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Additionally blacklist the cdc_ncm / cdc_eem / cdc_ether kernel modules so
        that usbmuxd can claim the Apple mux interface on iPhones. Only needed on
        desktop hosts; leave off on servers where cdc_ether USB networking may be
        in use.
      '';
    };
  };

  config = {
    services = {
      udisks2.enable = true;
      usbmuxd.enable = true;
      gvfs.enable = true;
    };
    environment.systemPackages = with pkgs; [
      sshfs
      libimobiledevice
      ifuse
      exfatprogs
      ntfs3g
      simple-mtpfs
      android-tools
      udiskie
    ];
    users.groups.adbusers = { };
    services.udev.packages = [ pkgs.libmtp ];
    services.udev.extraRules = ''
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
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="d00d", MODE="0664", GROUP="adbusers"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="d001", MODE="0664", GROUP="adbusers"

      # Auto-mount iPhones into the desktop user session on connect. add|change
      # (trust acceptance re-enumerates as a "change" event), remove unmounts.
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", ATTR{idProduct}=="12a8|12ab", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="iphone-mount.service"
      ACTION=="remove", SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", ATTR{idProduct}=="12a8|12ab", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="iphone-umount.service"

      # Android MTP auto-mount (ID_MTP_DEVICE is set by libmtp's udev rules).
      ACTION=="add|change", SUBSYSTEM=="usb", ENV{ID_MTP_DEVICE}=="1", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="android-mount.service"
      ACTION=="remove", SUBSYSTEM=="usb", ATTR{idVendor}=="18d1|0bb4|04e8|22b8|1004|413c|091e|12d1|8087|05c6|2717|2e17|109b|2b4c|1d6b|1f53", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="android-umount.service"
    '';
    boot.blacklistedKernelModules =
      [ "ipheth" ]
      ++ lib.optionals cfg.blacklistAppleNet [
        "cdc_ncm"
        "cdc_eem"
        "cdc_ether"
      ];
  };
}
