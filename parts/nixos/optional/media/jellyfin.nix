{ ... }:
{
  flake.modules.nixos.media-jellyfin =
{ config, lib, pkgs, ... }:

{

  services.jellyfin = {
    enable = true;
    user = "media";
    openFirewall = false;

    hardwareAcceleration = {
      enable = true;
      device = "/dev/dri/renderD128";
      type = "vaapi";
    };

    transcoding = {
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
      };
      hardwareEncodingCodecs = {
        hevc = true;
        av1 = false;
      };
    };

    forceEncodingConfig = true;
  };

  systemd.services.jellyfin.serviceConfig = {
    DevicePolicy = "auto";
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
      "/dev/kfd rw"
    ];
    SupplementaryGroups = [
      "video"
      "render"
    ];
  };

}

  ;
}
