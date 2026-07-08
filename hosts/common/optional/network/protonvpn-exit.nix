{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.networking.protonvpnExit;
in
{
  options.networking.protonvpnExit = {
    enable = mkEnableOption "Proton VPN exit node via WireGuard";

    privateKeyFile = mkOption {
      type = types.path;
      description = "Path to WireGuard private key file (use sops or a file)";
      example = config.sops.secrets."protonvpn-key".path;
    };

    address = mkOption {
      type = types.str;
      description = ''
        Client IP address from the Proton VPN WireGuard config.
        Found under [Interface] → Address.
      '';
      example = "10.2.0.2/32";
    };

    dns = mkOption {
      type = types.str;
      default = "10.2.0.1";
      description = "DNS server from the Proton VPN config";
    };

    peerPublicKey = mkOption {
      type = types.str;
      description = "Proton VPN server's public key (from [Peer] → PublicKey)";
    };

    peerEndpoint = mkOption {
      type = types.str;
      description = "Proton VPN server endpoint (from [Peer] → Endpoint)";
      example = "x.x.x.x:51820";
    };

    peerPresharedKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to preshared key file (from [Peer] → PresharedKey), if present";
    };

    allowedIPs = mkOption {
      type = types.listOf types.str;
      default = [ "0.0.0.0/0" "::/0" ];
      description = "Allowed IPs for the peer (default: route all traffic through VPN)";
    };
  };

  config = mkIf cfg.enable {

    networking.wireguard.interfaces = {
      proton0 = {
        ips = [ cfg.address ];
        privateKeyFile = cfg.privateKeyFile;
        # Put routes in table 100 so they don't override main table
        # Only forwarded traffic (fwmark 0x1) uses this route
        table = "100";
        peers = [
          {
            publicKey = cfg.peerPublicKey;
            presharedKeyFile = if cfg.peerPresharedKeyFile != null
              then cfg.peerPresharedKeyFile else null;
            endpoint = cfg.peerEndpoint;
            allowedIPs = cfg.allowedIPs;
            persistentKeepalive = 25;
          }
        ];
      };
    };

    # Keep nftables counter for debugging forwarded traffic from tailscale0
    systemd.services.protonvpn-nftables = {
      description = "Set up nftables counter for Proton VPN exit node";
      before = [ "protonvpn-routing.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.nftables}/bin/nft delete table inet protonvpn-exit 2>/dev/null || true
        ${pkgs.nftables}/bin/nft add table inet protonvpn-exit
        ${pkgs.nftables}/bin/nft add chain inet protonvpn-exit counter-prerouting { type filter hook prerouting priority -1\; policy accept\; }
        ${pkgs.nftables}/bin/nft add rule inet protonvpn-exit counter-prerouting iifname "tailscale0" counter
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;

    # Optimize UDP GRO for WireGuard performance
    systemd.services.fix-wireguard-gro = {
      description = "Fix UDP GRO for proton0";
      after = [ "wireguard-proton0.service" ];
      wants = [ "wireguard-proton0.service" ];
      script = ''
        /run/current-system/sw/bin/ethtool -K proton0 rx-udp-gro-forwarding on 2>/dev/null || true
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Route all forwarded traffic from tailscale0 through proton0
    systemd.services.protonvpn-routing = {
      description = "Set up Proton VPN exit node routing";
      after = [ "wireguard-proton0.service" ];
      wants = [ "wireguard-proton0.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.iproute2}/bin/ip route add default dev proton0 table 100 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip rule del iif tailscale0 table 100 priority 200 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip rule add iif tailscale0 table 100 priority 200
        ${pkgs.iproute2}/bin/ip rule del fwmark 0x1 table 100 priority 100 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip rule del fwmark 0x1/0x1 table 100 priority 100 2>/dev/null || true
        echo "Proton VPN exit node routing enabled"
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # WireGuard port
    networking.firewall.allowedUDPPorts = [ 51820 ];

    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];
  };
}
