{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Hetzner-specific optimizations

  # Disable IPv6 router advertisements (Hetzner network)
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
  };

  # SSH hardening for Hetzner
  services.openssh = {
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
      PermitUserEnvironment = false;
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
  };

  # Enhanced firewall for Hetzner cloud
  networking.firewall = {
    allowedTCPPorts = [
      22
      80
      443
    ];
    allowedUDPPorts = [ ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # Enable fail2ban for SSH
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "3600";
    ignoreIP = [
      "127.0.0.1/8"
      "::1/128"
      "10.0.0.0/8"
      "192.168.0.0/16"
    ];
  };

  # Optimize for Hetzner cloud init
  systemd.services.cloud-init.enable = lib.mkForce false;
}
