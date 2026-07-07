{ config, lib, pkgs, ... }:

let
  tunnelName = "alexa-homeassistant";
  tunnelDomain = "alexa-homeassistant.minerales.network";
  credentialsPath = config.sops.secrets."cloudflare-tunnel-credentials".path;

  configFile = pkgs.writeText "cloudflared-${tunnelName}.yml" ''
    tunnel: ${tunnelName}
    credentials-file: ${credentialsPath}
    ingress:
      - hostname: ${tunnelDomain}
        service: http://localhost:8123
      - service: http_status:404
  '';
in
{
  environment.systemPackages = with pkgs; [ cloudflared ];

  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel - ${tunnelName}";
    after = [ "network-online.target" "sops-install-secrets.service" ];
    wants = [ "network-online.target" "sops-install-secrets.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${configFile} run";
      Restart = "on-failure";
      RestartSec = 5;
      User = "root";
      StateDirectory = "cloudflared";
      StateDirectoryMode = "0700";
      # ProtectSystem = "strict";
      # ReadWritePaths = [ "/run/secrets" ];
      NoNewPrivileges = true;
    };
  };
}
