{
  config,
  lib,
  ...
}:

{
  sops.templates."vaultwarden.env" = {
    content = ''
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}
      SMTP_HOST=smtp.resend.com
      SMTP_PORT=2587
      SMTP_SECURITY=starttls
      SMTP_TIMEOUT=5
      SMTP_USERNAME=resend
      SMTP_PASSWORD=${config.sops.placeholder."resend-api-key"}
      SMTP_FROM=vault@minerales.network
      SMTP_FROM_NAME=Vaultwarden
    '';
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    domain = "vault.minerales.network";
    backupDir = "/var/lib/vaultwarden/backups";

    config = {
      SIGNUPS_ALLOWED = false;
    };

    environmentFile = config.sops.templates."vaultwarden.env".path;
  };
}
