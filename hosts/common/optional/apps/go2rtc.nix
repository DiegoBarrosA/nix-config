{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.go2rtc;
  xiaomiToken = "V1:9d2wTZnSKA8D7PcQtwbCZKjaasdBO2IZtsfXmV0vW6s/fNbjJIIQ8Fk7RRjKzDIGGLQCfRUmk6eIWUWUfO3/BF9SyiSoOOWDT/K6Od9RjXOKIgFiTryo4u0J1qMJZkbsEapqcTYEsSRBPGf5BftARrfJ0yHlJibzUANoCfcgsDE33WBin0NvJ5vQbkMPwPlem3vYq5GNcwh7dJw38OqjQHGYFoyEfRmQAqE8yqHz5DHeF+otFU3WwqbRmY8jaLIxp5w734VlY2mkdgUzp/aRz9O3SHaiW2LbHSVuZtaIEFg=";
in {
  services.go2rtc = {
    enable = true;
    settings = {
      api.listen = ":1984";
      rtsp.listen = ":8557";
      xiaomi.${"6704780226"} = xiaomiToken;
      streams = {
        xiaomi_cam = "xiaomi://6704780226:us@192.168.1.2?did=1078941680&model=chuangmi.camera.046c04";
        # Reolink E1 via the neolink RTSP bridge (see cameras.nix). go2rtc becomes
        # the single source for both cameras, consumed declaratively by Home Assistant.
        reolink_e1 = "rtsp://127.0.0.1:8554/reolink_e1";
      };
      webrtc.listen = ":8555";
      webrtc.ice_servers = [{ urls = [ "stun:stun.l.google.com:19302" ]; }];
    };
  };
}
