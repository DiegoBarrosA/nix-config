{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    # Base configuration
    ../common/global
    ../common/users/diego

    # Hardware support
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd # For GPU compute
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    # Core services
    ../common/optional/network/tailscale.nix
    ../common/optional/network/warp-exit.nix # "pirita" WARP exit-node container
    ../common/optional/desktop/devices.nix
    ../common/optional/network/hosts.nix
    ../common/optional/system/environment.nix

    # Automation modules
    ../common/optional/system/sops-secrets.nix
    ../common/optional/system/automated-storage.nix
    ./impermanence.nix # cobalto-specific impermanence (systemd stage 1)

    # Server configurations
    ../common/optional/desktop/amd-gpu-acceleration.nix # For AI/compute workloads
    # ../common/optional/nginx-tailscale.nix      # Disabled: replaced by minerales-network.nix
    ../common/optional/network/minerales-network.nix # Private minerales.network subdomains
    ../common/optional/network/cloudflare-tunnel.nix # Cloudflare Tunnel for Alexa Smart Home

    # Native services (replacing containers)
    # ../common/optional/media-stack-native.nix  # Replaced by native servarr-suite.nix
    ../common/optional/ai/llama-cpp-server.nix # llama.cpp with Vulkan for RX580 GPU acceleration
    # ../common/optional/ai/ollama-native.nix # Disabled: ROCm doesn't support gfx803/RX580
    ../common/optional/media/flaresolverr.nix # Cloudflare bypass proxy

    # Native dashboard and sync services
    ../common/optional/apps/homepage-native.nix # Native Homepage with full system integration
    ../common/optional/network/syncthing.nix # Native Syncthing (running as user service)
    ../common/optional/apps/couchdb.nix # CouchDB for Obsidian LiveSync backend
    # ../common/optional/apps/nextcloud.nix # Nextcloud with notes sync - DISABLED: fix setup issue

    # Container services (individual files)
    ../common/optional/ai/open-webui.nix # LLM chat interface
    # Individual native Servarr services
    ../common/optional/media/prowlarr.nix
    ../common/optional/media/sonarr.nix
    ../common/optional/media/radarr.nix
    ../common/optional/media/lidarr.nix
    ../common/optional/media/calibre.nix
    ../common/optional/media/lazylibrarian.nix
    ../common/optional/media/bazarr.nix
    ../common/optional/media/transmission.nix # Native Transmission BitTorrent client
    # Native media services
    ../common/optional/media/jellyfin.nix # Native Jellyfin media server

    # Multi-room audio
    ../common/optional/media/snapcast.nix

    # Communication
    ../common/optional/apps/matrix-synapse.nix # Private Matrix homeserver (Tailscale only)
    # ../common/optional/matrix-music-bot.nix # Disabled: container registry rate-limited

    # Media directory structure
    ../common/optional/media/media-directories.nix
    # "./common/optional/media-stack-native.nix"  # Disabled in favor of servarr-suite.nix        # Now uses native NixOS services

    ../common/optional/network/samba.nix
    ../common/optional/network/pihole.nix
    ../common/optional/apps/home-assistant.nix
    ../common/optional/media/miniflux.nix # RSS reader (Stylix-themed), embedded in HA dashboard
    ../common/optional/apps/go2rtc.nix
    ../common/optional/apps/cameras.nix
    ../common/optional/apps/vaultwarden.nix
    ../common/optional/media/music-assistant.nix

    # OpenCode remote access (API + web UI)
    ../common/optional/ai/opencode-server.nix

    # Invidious - YouTube frontend
    ../common/optional/media/invidious.nix

    # ZenNotes - keyboard-first Markdown notes web UI
    ../common/optional/apps/zennotes.nix

    # Boot configuration
    ../common/optional/system/systemdboot.nix
  ];

  # Basic server configuration
  #
  #
  #

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
    #
    spec-kit
    cursor-cli
  ];

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; })
      (lib.filterAttrs (name: _: name != "private-config") inputs);
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  networking = {
    hostName = "cobalto";
    useDHCP = false;
    interfaces = {
      enp7s0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = "10.0.0.1";
            prefixLength = 16;
          }
          {
            address = "192.168.1.85";
            prefixLength = 24;
          }
        ];
      };
    };
    firewall.allowedTCPPorts = [
      21063 # HomeKit bridge for Siri (default HA port)
      1984 8554 8555 8557 # go2rtc API, RTSP, WebRTC; neolink RTSP
    ];
    firewall.allowedUDPPorts = [
      50000 50001 50002 50003 50004 50005 # go2rtc WebRTC
    ];
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  # Enable Pi-hole DNS server — used by the exit-node DNS chain to resolve
  # minerales.network (via custom dnsmasq entries in pihole.nix).
  networking.pihole.enable = true;

  # Server configuration
  security.polkit.enable = true;
  services.dbus.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Act as a plain Tailscale exit node (cobalto already advertises one via the
  # shared tailscale.nix). "server" enables IP forwarding + masquerade so other
  # tailnet devices (rubi, iPhone) can route their internet through cobalto.
  # Combined with the WAN CAKE shaper below, cobalto becomes an SQM gateway that
  # kills PLDT uplink bufferbloat for every device using it as an exit node.
  services.tailscale.useRoutingFeatures = "server";

  # Cobalto's tailnet IP — used by pirita's DNS forwarder and Pi-hole to resolve
  # minerales.network for exit-node clients (see warp-exit.nix, pihole.nix).
  networking.warpExit.cobaltoTailscaleIp = "100.69.115.53";

  # WAN egress SQM: shape internet-bound traffic with CAKE to ~90% of the PLDT
  # upload rate so the queue forms here (and drains smartly) instead of piling up
  # in the ISP router's dumb buffer. Local LAN/tailnet destinations are exempted
  # so media serving (Jellyfin/Samba) to the LAN is NOT throttled to WAN speed.
  # Tune WAN_RATE: lower if latency-under-load is still high, raise if throughput
  # feels capped. Test with: ping 1.1.1.1 while saturating the uplink.
  systemd.services.wan-sqm = {
    description = "CAKE SQM on WAN egress (anti-bufferbloat)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      TC=${pkgs.iproute2}/bin/tc
      DEV=enp7s0
      # Tuned empirically: latency-under-load stays ~30ms at 200, ~67ms at 240,
      # then collapses to ~2000ms at 270 (true uplink ceiling). 200 gives lowest
      # latency + margin below the cliff. Re-tune if the PLDT plan changes.
      WAN_RATE=200mbit

      $TC qdisc del dev $DEV root 2>/dev/null || true

      # HTB just splits traffic into two classes; CAKE does the actual shaping.
      # default 10 = internet (shaped); local dsts are filtered into 20 (unshaped).
      $TC qdisc add dev $DEV root handle 1: htb default 10
      $TC class add dev $DEV parent 1: classid 1:10 htb rate 1000mbit ceil 1000mbit
      $TC class add dev $DEV parent 1: classid 1:20 htb rate 1000mbit ceil 1000mbit
      # CAKE with per-internal-host fairness (so one device can't starve others).
      $TC qdisc add dev $DEV parent 1:10 handle 10: cake bandwidth $WAN_RATE nat dual-srchost
      $TC qdisc add dev $DEV parent 1:20 handle 20: fq_codel

      # Exempt local IPv4 destinations from shaping -> class 1:20
      $TC filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 192.168.0.0/16 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 10.0.0.0/8 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 100.64.0.0/10 flowid 1:20
      # Exempt local IPv6 (tailnet ULA + link-local) -> class 1:20.
      # IPv6 filters must use a different priority band than IPv4 (prio 2), else
      # tc rejects them with "Protocol mismatch for filter with specified priority".
      $TC filter add dev $DEV parent 1: protocol ipv6 prio 2 u32 match ip6 dst fd7a:115c:a1e0::/48 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ipv6 prio 2 u32 match ip6 dst fe80::/10 flowid 1:20
    '';
  };

  # Disable 32-bit OpenGL (no 32-bit apps on this server; avoids nixpkgs i686-linux eval issue)
  hardware.graphics.enable32Bit = false;

  # Enable user lingering for systemd user services
  users.users.diego.linger = true;

  # Camera proxy services
  services.cameras = {
    enable = true;
    reolink = {
      enable = true;
      ip = "192.168.1.65";
      rtspPort = 8554;
    };
  };

  # Bluetooth for SwitchBot IoT devices
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Matter smart home protocol server
  services.matter-server.enable = true;

  # Hardware configuration (non-gaming specific)
  boot.extraModprobeConfig = "options vfio-pci ids=10ec:818b";

  # ACME/Let's Encrypt is configured in minerales-network.nix for wildcard certs

  # ZenNotes web UI — vault at /mnt/media/Obsidian/obsidiana
  services.zennotes = {
    enable = true;
    vaultPath = "/mnt/media/Obsidian/obsidiana";
  };

  # OpenCode server for remote access (Android app + web UI)
  # Proxied through nginx on opencode.minerales.network
  services.opencode-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4096;
    passwordFile = config.sops.secrets."opencode-server-password".path;
  };

  system.stateVersion = "22.11";

  # llama.cpp server configuration for local LLM inference
  # Uses Vulkan backend for RX 460 GPU acceleration (ROCm doesn't support gfx803)
  services.llama-cpp-server = {
    enable = true;
    # 3B Q8_0 model - fits entirely in 4GB VRAM for full GPU acceleration
    # Can be changed to any HuggingFace GGUF model or local path
    model = "bartowski/Llama-3.2-3B-Instruct-GGUF:Q8_0";
    # Port 11435 (similar to ollama's 11434, avoids conflict with calibre on 8081)
    port = 11435;
    contextSize = 8192;
    gpuLayers = 99;  # All 29 layers fit on GPU with 3B Q8 model (~4.1G of 4G VRAM used)
  };

  # deploy-rs and Nix commands on the remote expect a properly laid-out store.
  # Ensure these exist at boot (e.g. after impermanence or minimal store).
  # NOTE: /nix/store is normally a read-only filesystem, so these writes will
  # fail harmlessly; guard with `|| true` so activation never aborts here.
  system.activationScripts.ensureNixStoreLayout = ''
    if [ ! -e /nix/store/version ]; then
      (echo '7' > /nix/store/version && chmod 444 /nix/store/version) || true
    fi
    if [ ! -d /nix/store/derivations ]; then
      (mkdir -p /nix/store/derivations && chmod 755 /nix/store/derivations) || true
    fi
  '';
}
