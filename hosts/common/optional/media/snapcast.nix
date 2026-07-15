{ config, lib, pkgs, ... }:

{
  services.snapserver = {
    enable = true;

    settings = {
      stream = {
        source = "pipe:///tmp/snapfifo?name=default";
      };

      http = {
        enabled = true;
        port = 1780;
        bind_to_address = "127.0.0.1";
      };

      tcp-streaming = {
        enabled = true;
        port = 1704;
      };

      tcp-control = {
        enabled = true;
        port = 1705;
      };
    };

    openFirewall = false;
  };

  systemd.tmpfiles.rules = [
    "f /tmp/snapfifo 0666 root root -"
  ];

  users.users.snapserver = {
    isSystemUser = true;
    group = "snapserver";
    extraGroups = [ "audio" ];
  };
  users.groups.snapserver = { };
}
