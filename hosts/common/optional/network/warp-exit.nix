{ config, lib, pkgs, ... }:
let
  cfg = config.networking.warpExit;
in
{
  options.networking.warpExit = {
    cobaltoTailscaleIp = lib.mkOption {
      type = lib.types.str;
      description = "Tailscale IPv4 address of the cobalto host (Pi-hole DNS target for exit-node clients)";
    };
  };

  config = {
    # "pirita" — a containerized Tailscale exit node that egresses through
    # Cloudflare WARP, running on podman.
    #
    # WARP (WireGuard) and Tailscale run together in a SINGLE podman network
    # namespace where WARP is the only default route. That means Tailscale's own
    # (correct) exit-node masquerade forwards traffic cleanly — no host-level
    # policy routing or hand-rolled SNAT (which is what broke the earlier Proton
    # attempt). cobalto's own traffic is untouched; only traffic from tailnet
    # devices that SELECT pirita as their exit node goes through WARP.
    #
    # Purpose: tunnel IPv4 past the ISP CGNAT (fixes SYN-loss on IPv4-only sites).
    # It's a per-device toggle and, like any tunnel, cuts throughput while in use.
    #
    # Manual steps after first deploy:
    #   1. Add the WARP private key to cobalto's secrets.yaml as `warp-key`
    #      (the `PrivateKey =` line from `wgcf generate`).
    #   2. In the Tailscale admin console, approve pirita's exit-node route.

    virtualisation.podman.enable = true;

    # WARP WireGuard private key (from `wgcf generate`).
    sops.secrets."warp-key" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # gluetun env: the WARP private key.
    sops.templates."pirita-warp.env".content = ''
      WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."warp-key"}
    '';

    # tailscale sidecar env: reuse cobalto's existing REUSABLE tailscale auth key
    # (a new tailnet node "pirita" registers under the same key; no new key).
    sops.templates."pirita-ts.env".content = ''
      TS_AUTHKEY=${config.sops.placeholder."tailscale-key"}
    '';

    # Persistent tailscale state so pirita keeps its node identity across restarts.
    systemd.tmpfiles.rules = [
      "d /var/lib/pirita-tailscale 0700 root root -"
    ];

    # Wire up exit-node forwarding inside the pirita netns. gluetun keeps eth0 as
    # the default route and only sends its OWN traffic through WARP, and its
    # firewall won't let Tailscale install exit-node rules — so we set them up
    # ourselves once both containers are up (tun0 = WARP iface, table 52 = the
    # tailnet routes Tailscale installs):
    #   1. FORWARD ACCEPT so transit traffic passes,
    #   2. MASQUERADE out tun0 so forwarded packets get WARP's source,
    #   3. a high-priority rule sending tailnet-destined replies back via
    #      tailscale0 (table 52), ahead of gluetun's rule that would misroute them,
    #   4. MSS clamp for the Tailscale-over-WARP double tunnel.
    systemd.services.pirita-routing = {
      description = "Exit-node forwarding rules inside the pirita WARP netns";
      after = [ "podman-pirita.service" "podman-pirita-ts.service" ];
      wants = [ "podman-pirita.service" "podman-pirita-ts.service" ];
      partOf = [ "podman-pirita.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        P="${pkgs.podman}/bin/podman exec pirita"
        # Wait until WARP (tun0) and the tailnet route table (52) are ready.
        ready=0
        for i in $(seq 1 40); do
          if $P ip link show tun0 >/dev/null 2>&1 && $P ip route show table 52 2>/dev/null | grep -q tailscale0; then
            ready=1; break
          fi
          sleep 3
        done
        if [ "$ready" != 1 ]; then
          echo "pirita-routing: tun0/table52 not ready, giving up" >&2; exit 1
        fi

        $P iptables -P FORWARD ACCEPT
        $P iptables -t nat -C POSTROUTING -o tun0 -j MASQUERADE 2>/dev/null \
          || $P iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
        $P ip rule del to 100.64.0.0/10 lookup 52 priority 50 2>/dev/null || true
        $P ip rule add to 100.64.0.0/10 lookup 52 priority 50
        $P iptables -t mangle -C FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null \
          || $P iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        echo "pirita-routing: applied"
      '';
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        # WARP tunnel via gluetun in custom-WireGuard mode. Owns the shared netns
        # and enables IP forwarding so the tailscale sidecar can route through it.
        pirita = {
          image = "docker.io/qmcgaw/gluetun:latest";
          autoStart = true;
          extraOptions = [
            "--cap-add=NET_ADMIN"
            "--device=/dev/net/tun:/dev/net/tun"
            "--sysctl=net.ipv4.ip_forward=1"
            "--sysctl=net.ipv6.conf.all.forwarding=1"
          ];
          environmentFiles = [ config.sops.templates."pirita-warp.env".path ];
          environment = {
            VPN_SERVICE_PROVIDER = "custom";
            VPN_TYPE = "wireguard";
            VPN_ENDPOINT_IP = "162.159.192.1"; # engage.cloudflareclient.com
            VPN_ENDPOINT_PORT = "2408";
            WIREGUARD_PUBLIC_KEY = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="; # Cloudflare WARP
            WIREGUARD_ADDRESSES = "172.16.0.2/32,2606:4700:110:8e31:c7c7:d58a:64a6:1b46/128";
            WIREGUARD_MTU = "1280";
            # Allow tailscale to reach the LAN directly instead of via WARP.
            # NOTE: do NOT include the tailnet (100.64.0.0/10) here — gluetun turns
            # each entry into an `ip rule ... lookup 199` that would hijack reply
            # traffic to tailnet clients away from tailscale0 (breaks forwarding).
            # The pirita-routing service below steers the tailnet via table 52.
            FIREWALL_OUTBOUND_SUBNETS = "192.168.1.0/24,10.0.0.0/16";
            # Disable gluetun's killswitch: it sets FORWARD DROP and manages
            # iptables, which blocks Tailscale's exit-node forwarding/masquerade
            # rules. We don't need it — the netns default route IS WARP, so there
            # is nothing to leak to; with the firewall off, Tailscale installs its
            # own FORWARD-accept + masquerade and forwarded traffic flows.
            FIREWALL = "off";
            TZ = "America/Santiago";
          };
        };

        # Tailscale sidecar sharing pirita's netns; advertises the exit node.
        pirita-ts = {
          image = "docker.io/tailscale/tailscale:latest";
          autoStart = true;
          dependsOn = [ "pirita" ];
          extraOptions = [
            "--network=container:pirita"
            "--cap-add=NET_ADMIN"
            "--device=/dev/net/tun:/dev/net/tun"
          ];
          environmentFiles = [ config.sops.templates."pirita-ts.env".path ];
          environment = {
            TS_HOSTNAME = "pirita";
            TS_EXTRA_ARGS = "--advertise-exit-node --accept-dns=true";
            TS_STATE_DIR = "/var/lib/tailscale";
            TS_USERSPACE = "false";
            TS_AUTH_ONCE = "false";
          };
          volumes = [
            "/var/lib/pirita-tailscale:/var/lib/tailscale"
          ];
        };
      };
    };
  };
}
