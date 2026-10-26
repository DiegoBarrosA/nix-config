{ ... }:
{
  flake.modules.nixos.media-tdarr =
{ config, lib, pkgs, ... }:

let
  dataDir = "/nix/storage/tdarr";
in
{

  services.tdarr = {
    enable = true;
    user = "media";
    group = "media";
    dataDir = dataDir;

    server = {
      enable = true;
      auth.enable = true;
      environmentFile = config.sops.secrets."tdarr-server-env".path;
      openFirewall = false;
    };

    nodes.main = {
      environmentFile = config.sops.secrets."tdarr-node-env".path;
      workers = {
        transcodeCPU = 2;
        transcodeGPU = 2;
        healthcheckCPU = 1;
        healthcheckGPU = 0;
      };
    };
  };

  systemd.services."tdarr-node-main".serviceConfig = {
    PrivateDevices = false;
    DevicePolicy = "auto";
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
      "/dev/kfd rw"
    ];
    ReadWritePaths = [
      dataDir
      "/srv/media"
    ];
    SupplementaryGroups = [
      "video"
      "render"
    ];
  };

  systemd.services."tdarr-server".serviceConfig = {
    PrivateDevices = false;
    DevicePolicy = "auto";
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
    ];
    ReadWritePaths = [
      dataDir
      "/srv/media"
    ];
  };

  users.users.media.extraGroups = [
    "video"
    "render"
  ];

}

  ;
}
