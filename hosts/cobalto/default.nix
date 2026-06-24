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
    ../common/optional/tailscale.nix
    ../common/optional/devices.nix
    ../common/optional/hosts.nix
    ../common/optional/environment.nix

    # Automation modules
    ../common/optional/sops-secrets.nix
    ../common/optional/automated-storage.nix
    ./impermanence.nix # cobalto-specific impermanence (systemd stage 1)
    # ./sops-employer.nix # Employer-specific secrets from private-config - TEMPORARILY DISABLED

    # Server configurations
    ../common/optional/amd-gpu-acceleration.nix # For AI/compute workloads
    # ../common/optional/nginx-tailscale.nix      # Disabled: replaced by minerales-network.nix
    ../common/optional/minerales-network.nix # Private minerales.network subdomains
    ../common/optional/cloudflare-tunnel.nix # Cloudflare Tunnel for Alexa Smart Home

    # Native services (replacing containers)
    # ../common/optional/media-stack-native.nix  # Replaced by native servarr-suite.nix
    ../common/optional/llama-cpp-server.nix # llama.cpp with Vulkan for RX580 GPU acceleration
    # ../common/optional/ollama-native.nix # Disabled: ROCm doesn't support gfx803/RX580
    ../common/optional/flaresolverr.nix # Cloudflare bypass proxy

    # Native dashboard and sync services
    ../common/optional/homepage-native.nix # Native Homepage with full system integration
    ../common/optional/syncthing.nix # Native Syncthing (running as user service)
    ../common/optional/couchdb.nix # CouchDB for Obsidian LiveSync backend
    # ../common/optional/nextcloud.nix # Nextcloud with notes sync - DISABLED: fix setup issue

    # Container services (individual files)
    ../common/optional/open-webui.nix # LLM chat interface
    # Individual native Servarr services
    ../common/optional/prowlarr.nix
    ../common/optional/sonarr.nix
    ../common/optional/radarr.nix
    ../common/optional/lidarr.nix
    ../common/optional/calibre.nix
    ../common/optional/lazylibrarian.nix
    ../common/optional/bazarr.nix
    ../common/optional/transmission.nix # Native Transmission BitTorrent client
    # Native media services
    ../common/optional/jellyfin.nix # Native Jellyfin media server

    # Multi-room audio
    ../common/optional/snapcast.nix

    # Communication
    ../common/optional/matrix-synapse.nix # Private Matrix homeserver (Tailscale only)
    # ../common/optional/matrix-music-bot.nix # Disabled: container registry rate-limited

    # Media directory structure
    ../common/optional/media-directories.nix
    # "./common/optional/media-stack-native.nix"  # Disabled in favor of servarr-suite.nix        # Now uses native NixOS services

    ../common/optional/samba.nix
    ../common/optional/home-assistant.nix
    ../common/optional/go2rtc.nix
    ../common/optional/music-assistant.nix

    # OpenCode remote access (API + web UI)
    ../common/optional/opencode-server.nix

    # Boot configuration
    ../common/optional/systemdboot.nix
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
      enp6s0 = {
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
      1984 8554 8555 # go2rtc API, RTSP, WebRTC
    ];
    firewall.allowedUDPPorts = [
      50000 50001 50002 50003 50004 50005 # go2rtc WebRTC
    ];
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  # Server configuration
  security.polkit.enable = true;
  services.dbus.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Disable 32-bit OpenGL (no 32-bit apps on this server; avoids nixpkgs i686-linux eval issue)
  hardware.graphics.enable32Bit = false;

  # Enable user lingering for systemd user services
  users.users.diego.linger = true;

  # Bluetooth for SwitchBot IoT devices
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Matter smart home protocol server
  services.matter-server.enable = true;

  # Hardware configuration (non-gaming specific)
  boot.extraModprobeConfig = "options vfio-pci ids=10ec:818b";

  # ACME/Let's Encrypt is configured in minerales-network.nix for wildcard certs

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
