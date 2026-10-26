{ ... }:
{
  flake.modules.homeManager.desktop-common-mobile-automount =
{ pkgs, lib, customPkgs ? { }, ... }:
let
  deviceMount = customPkgs.device-mount or null;
in
{
  # udev (see hosts/common/optional/desktop/devices.nix) starts these user units
  # on device connect via SYSTEMD_USER_WANTS. WantedBy graphical-session.target
  # also covers devices already plugged in when the session starts.
  systemd.user.services = lib.mkIf (deviceMount != null) {
    iphone-mount = {
      Unit = {
        Description = "Mount iPhone";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${deviceMount}/bin/device-mount iphone";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    iphone-umount = {
      Unit = {
        Description = "Unmount iPhone";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${deviceMount}/bin/device-mount umount-iphone";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    android-mount = {
      Unit = {
        Description = "Mount Android MTP device";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${deviceMount}/bin/device-mount android";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    android-umount = {
      Unit = {
        Description = "Unmount Android MTP device";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${deviceMount}/bin/device-mount umount-mtp";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
};}
