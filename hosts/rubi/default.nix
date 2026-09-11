{
  inputs,
  lib,
  config,
  pkgs,
  desktop,
  ...
}:
{
  imports = [

    ../common/global
    ../common/users/diego

    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    inputs.stylix.nixosModules.stylix

    inputs.musnix.nixosModules.musnix

    ../common/optional/network/tailscale.nix
    ./sops.nix

    ./impermanence.nix

    ./bootloader.nix

    ../common/optional/desktop/devices.nix

    ../common/optional/ai/opencode-server.nix

    ../common/optional/ai/ollama-vulkan.nix

    ../common/optional/desktop/virtualization.nix
    inputs.nixvirt.nixosModules.default

    ../common/optional/desktop/sunshine.nix

    inputs.private-config.nixosModules.work
  ];

  console = {
    packages = [ pkgs.terminus_font ];
    font = "ter-v32b";
    earlySetup = true;
  };

  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "rd.systemd.show_status=false"
    "systemd.show_status=false"
    "udev.log_level=3"
    "nowatchdog"
    "amdgpu.gpu_recovery=1"
  ];

  nixpkgs.overlays = [ (final: prev: {
    noto-fonts-color-emoji = prev.noto-fonts-monochrome-emoji;
  }) ];

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) (
      lib.filterAttrs (name: _: name != "private-config") inputs
    );
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };

    extraOptions = "!include /etc/nix/github-access-token.conf";
  };

  environment.systemPackages = with pkgs; [

    pciutils
    usbutils
    lshw
    qt6.qtwayland
    sbctl
    openssl

    (writeShellScriptBin "exit-on" "exec tailscale set --exit-node=amatista --exit-node-allow-lan-access=true")
    (writeShellScriptBin "exit-off" "exec tailscale set --exit-node=")
  ];

  networking = {
    hostName = "rubi";
    networkmanager.enable = true;

    networkmanager.wifi.powersave = false;
    firewall = {
      enable = true;

      allowedTCPPorts = [ 22 22000 ];
      allowedUDPPorts = [ 22000 21027 ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  services.resolved.enable = true;

  services.tailscale.useRoutingFeatures = "client";

  systemd.services.tailscale-exit-node-guard = {
    description = "Clear the Tailscale exit node when amatista is unreachable";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.tailscale}/bin/tailscale status --json \
        | ${pkgs.jq}/bin/jq -e '.ExitNodeStatus' >/dev/null 2>&1 || exit 0
      if ! ${pkgs.tailscale}/bin/tailscale ping --c 3 --timeout 3s amatista >/dev/null 2>&1; then
        echo "amatista unreachable; clearing exit node"
        ${pkgs.tailscale}/bin/tailscale set --exit-node=
      fi
    '';
  };
  systemd.timers.tailscale-exit-node-guard = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
    };
  };

  services.upower.enable = true;

  automount.blacklistAppleNet = true;

  services.opencode-server = {
    enable = true;
    host = "0.0.0.0";
    port = 4096;
    passwordFile = config.sops.secrets."opencode-server-password".path;
    secretEnv = {
      OPENCODE_API_KEY = config.sops.secrets."opencode-api-key".path;
      GITHUB_TOKEN = config.sops.secrets."github-token".path;
    };
  };

  services.ollama-vulkan = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;
    loadModels = [
      "qwen3:4b"
      "qwen2.5:14b"
      "qwen2.5-coder:7b"
      "qwen2.5-coder:14b"
      "deepseek-coder-v2:16b"
      "deepseek-r1:8b"
    ];
  };

  security.polkit.enable = true;
  services.dbus.enable = true;
  security.sudo.wheelNeedsPassword = false;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
  };

  musnix.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 64;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 512;
      };
    };

    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "~alsa_input.*"; }
            { "node.name" = "~alsa_output.*"; }
          ];
          actions.update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        }
      ];
    };
  };
  security.rtkit.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.geoclue2.enable = true;
  services.localtimed.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  hardware.brillo.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_HL-1202";
        location = "Home";
        deviceUri = "usb://Brother/HL-1200%20series";
        model = "drv:///brlaser.drv/br1200.ppd";
        ppdOptions.PageSize = "A4";
      }
    ];
    ensureDefaultPrinter = "Brother_HL-1202";
  };

  programs.nix-ld.enable = true;

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      customPkgs = inputs.self.packages."x86_64-linux";
      privateConfig = inputs.private-config or { };
      inherit desktop;
    };
    users.diego = {
      imports = [
        inputs.stylix.homeModules.stylix
        ../../modules/home-manager/colors.nix
        ../../modules/home-manager/kanshi.nix
        ../../modules/home-manager/monitors.nix
        ../../modules/home-manager/bar.nix
        inputs.ai-tooling.homeManagerModules.opencode-config
        inputs.ai-tooling.homeManagerModules.mcp-config
        inputs.ai-tooling.homeManagerModules.antigravity-config
        inputs.ai-tooling.homeManagerModules.claude-code-config
        inputs.ai-tooling.homeManagerModules.claude-desktop-config
        inputs.ai-tooling.homeManagerModules.cursor-config
        inputs.ai-tooling.homeManagerModules.jcode-config
        inputs.ai-tooling.homeManagerModules.ai-skills
        inputs.ai-tooling.homeManagerModules.ai-system-prompt
        inputs.ai-tooling.homeManagerModules.happier-config
        inputs.private-config.homeManagerModules.workMcpConfig
        inputs.private-config.homeManagerModules.workClaudeDesktopMcpConfig
        inputs.private-config.homeManagerModules.workExtras
        ../../home/diego/rubi.nix
      ];
    };
  };

  system.activationScripts.home-manager-reapply = lib.mkAfter ''
    ${config.systemd.package}/bin/systemctl restart home-manager-diego.service
  '';

  system.stateVersion = "25.11";

  systemd.services.NetworkManager-wait-online.enable = false;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  boot.blacklistedKernelModules = [ "8250" ];

  users.users.diego.extraGroups = [ "docker" "libvirtd" ];
}
