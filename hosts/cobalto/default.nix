{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [

    ../common/global
    ../common/users/diego

    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    ../common/optional/network/tailscale.nix
    ../common/optional/desktop/devices.nix
    ../common/optional/network/hosts.nix
    ../common/optional/system/environment.nix

    ../common/optional/system/sops-secrets.nix
    ../common/optional/system/automated-storage.nix
    ../common/optional/system/offsite-backup.nix
    ./impermanence.nix

    ../common/optional/system/webtheming.nix

    inputs.private-config.nixosModules.workSecrets

    ../common/optional/desktop/amd-gpu-acceleration.nix

    ../common/optional/network/minerales-network.nix

    ../common/optional/ai/llama-cpp-server.nix

    ../common/optional/media/flaresolverr.nix

    ../common/optional/apps/homepage-native.nix
    ../common/optional/network/syncthing.nix
    ../common/optional/apps/couchdb.nix

    ../common/optional/ai/open-webui.nix

    ../common/optional/media/prowlarr.nix
    ../common/optional/media/sonarr.nix
    ../common/optional/media/radarr.nix
    ../common/optional/media/lidarr.nix
    ../common/optional/media/calibre.nix
    ../common/optional/media/lazylibrarian.nix
    ../common/optional/media/bazarr.nix
    ../common/optional/media/transmission.nix

    ../common/optional/media/jellyfin.nix

    ../common/optional/media/snapcast.nix

    ../common/optional/apps/matrix-synapse.nix

    ../common/optional/media/media-directories.nix

    ../common/optional/network/samba.nix
    ../common/optional/network/pihole.nix
    ../common/optional/apps/home-assistant.nix
    ../common/optional/media/miniflux.nix
    ../common/optional/apps/go2rtc.nix
    ../common/optional/apps/cameras.nix
    ../common/optional/apps/vaultwarden.nix
    ../common/optional/media/music-assistant.nix
    ../common/optional/media/po-token-server.nix

    ../common/optional/ai/opencode-server.nix

    ../common/optional/apps/zennotes.nix

    ../common/optional/system/systemdboot.nix
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [

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
      21063
      1984 8554 8555 8557
    ];
    firewall.allowedUDPPorts = [
      50000 50001 50002 50003 50004 50005
    ];
    firewall.trustedInterfaces = [ "tailscale0" ];
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  networking.pihole.enable = true;

  security.polkit.enable = true;
  services.dbus.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.tailscale.useRoutingFeatures = "both";

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
      WAN_RATE=200mbit

      $TC qdisc del dev $DEV root 2>/dev/null || true

      $TC qdisc add dev $DEV root handle 1: htb default 10
      $TC class add dev $DEV parent 1: classid 1:10 htb rate 1000mbit ceil 1000mbit
      $TC class add dev $DEV parent 1: classid 1:20 htb rate 1000mbit ceil 1000mbit
      $TC qdisc add dev $DEV parent 1:10 handle 10: cake bandwidth $WAN_RATE nat dual-srchost
      $TC qdisc add dev $DEV parent 1:20 handle 20: fq_codel

      $TC filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 192.168.0.0/16 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 10.0.0.0/8 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 100.64.0.0/10 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ipv6 prio 2 u32 match ip6 dst fd7a:115c:a1e0::/48 flowid 1:20
      $TC filter add dev $DEV parent 1: protocol ipv6 prio 2 u32 match ip6 dst fe80::/10 flowid 1:20
    '';
  };

  hardware.graphics.enable32Bit = false;

  users.users.diego.linger = true;

  services.cameras = {
    enable = true;
    reolink = {
      enable = true;
      ip = "192.168.1.19";
      rtspPort = 8554;
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.matter-server.enable = true;

  boot.extraModprobeConfig = "options vfio-pci ids=10ec:818b";

  services.zennotes = {
    enable = true;
    vaultPath = "/mnt/media/Obsidian/obsidiana";
  };

  services.po-token-server.enable = true;

  services.opencode-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4096;
    passwordFile = config.sops.secrets."opencode-server-password".path;
  };

  backups.restic = {
    enable = true;
    remote = {
      bucket = "bitwarden-backup";
      envFile = config.sops.templates."restic.env".path;
    };
  };

  system.stateVersion = "22.11";

  services.llama-cpp-server = {
    enable = true;

    model = "bartowski/Llama-3.2-3B-Instruct-GGUF:Q8_0";

    port = 11435;
    contextSize = 8192;
    gpuLayers = 99;
  };

  system.activationScripts.ensureNixStoreLayout = ''
    if [ ! -e /nix/store/version ]; then
      (echo '7' > /nix/store/version && chmod 444 /nix/store/version) || true
    fi
    if [ ! -d /nix/store/derivations ]; then
      (mkdir -p /nix/store/derivations && chmod 755 /nix/store/derivations) || true
    fi
  '';
}
