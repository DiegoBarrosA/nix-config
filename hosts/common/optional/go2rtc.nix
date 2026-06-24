{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.go2rtc;
in {
  sops.secrets = {
    "camera-reolink-user" = { };
    "camera-reolink-pass" = { };
    "camera-xiaomi-token" = { };
  };

  sops.templates."go2rtc-env" = {
    content = ''
      REOLINK_USER=${config.sops.placeholder.camera-reolink-user}
      REOLINK_PASS=${config.sops.placeholder.camera-reolink-pass}
      XIAOMI_TOKEN=${config.sops.placeholder.camera-xiaomi-token}
    '';
  };

  services.go2rtc = {
    enable = true;
    settings = {
      api.listen = "127.0.0.1:1984";
      streams = {
        reolink_e1 = ''
          reolink://''${REOLINK_USER}:''${REOLINK_PASS}@192.168.1.7/'';
        xiaomi_cam = ''
          xiaomi://192.168.1.2?token=''${XIAOMI_TOKEN}'';
      };
      webrtc.listen = ":8555";
      webrtc.ice_servers = [{ urls = [ "stun:stun.l.google.com:19302" ]; }];
    };
  };

  systemd.services.go2rtc = {
    serviceConfig.EnvironmentFile = config.sops.templates."go2rtc-env".path;
  };
}
