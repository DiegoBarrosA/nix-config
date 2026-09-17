{ config, lib, pkgs, ... }:

{

  users.groups.media = {
    gid = 1001;
  };

  users.users.media = {
    isSystemUser = true;
    uid = 1001;
    group = "media";
    extraGroups = [
      "video"
      "render"
    ];
    home = "/var/empty";
    createHome = false;
  };

  users.users.diego.extraGroups = [
    "media"
    "docker"
  ];

}
