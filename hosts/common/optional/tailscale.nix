{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-key".path;
    # Usar Tailscale como exit node para acceso privado
    extraUpFlags = [
      "--ssh"  # Habilita Tailscale SSH
      "--accept-dns=true"  # Accept Tailscale DNS configuration
    ];
  };

  # Exponer el servicio de Tailscale para que nginx pueda escuchar en la interfaz Tailscale
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Reset tailscale config on next start to clear old flags (like tag:server)
  systemd.services.tailscaled-autoconnect = lib.mkForce {
    wantedBy = [ "multi-user.target" ];
    after = [ "tailscale.service" "sops-nix.service" ];
    script = ''
      if [ -f /run/secrets/tailscale-key ]; then
        echo "Server needs authentication, sending auth key"
        ${pkgs.tailscale}/bin/tailscale up --reset \
          --auth-key file:///run/secrets/tailscale-key \
          --ssh \
          --accept-dns=true
      else
        echo "No tailscale auth key found, skipping"
      fi
    '';
    serviceConfig = {
      Type = "simple";
    };
  };

  # Nota: Tailscale da una IP como 100.x.x.x que puedes usar en nginx
  # Ejemplo: Si Cobalto obtiene 100.120.1.1 en Tailscale
  # nginx escuchará en esa IP en lugar de la IP pública
}

