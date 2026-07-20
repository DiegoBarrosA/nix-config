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
    # Base configuration
    ../common/global
    ../common/users/diego

    # Hardware support
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    # Stylix theming
    inputs.stylix.nixosModules.stylix

    # Core services
    ../common/optional/network/tailscale.nix
    ./sops.nix # rubi-specific SOPS secrets (minimal for desktop)

    # Impermanence (rubi-specific for desktop)
    ./impermanence.nix

    # Boot configuration (systemd-boot for fast native UEFI boot)
    ./bootloader.nix

    # USB/iOS/device mounting support
    ../common/optional/desktop/devices.nix

    # Steam gaming (GameMode, gamescope, Proton-GE) tuned for the 680M APU
    ../common/optional/desktop/steam.nix

    # OpenCode remote access (API + web UI)
    ../common/optional/ai/opencode-server.nix

    # Local LLM inference (Vulkan on AMD 680M APU — model cache at /var/lib/llama-cpp)
    ../common/optional/ai/llama-cpp-server.nix

    # libvirt/KVM + virt-manager (Windows 11 VM with virtio-gpu)
    # ../common/optional/desktop/virtualization.nix
    inputs.nixvirt.nixosModules.default
    # ./win11-vm.nix

    # Work (customer) system module — VPN, endpoint security, work secrets.
    # Contents are defined entirely in private-config.
    inputs.private-config.nixosModules.work
  ];

  # TTY console font - large bold Terminus for hacky TUI aesthetic
  console = {
    packages = [ pkgs.terminus_font ];
    font = "ter-v32b"; # 32pt bold - clean monospace look
    earlySetup = true; # Required for systemd stage 1 initrd
  };

  # Quiet boot: suppress kernel and systemd messages before tuigreet.
  # consoleLogLevel=3 hides err+warn+notice+info+debug (alert/crit/emerg
  # remain visible). Set via the NixOS option so we don't end up with two
  # competing loglevel= values on the kernel cmdline.
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "rd.systemd.show_status=false"
    "systemd.show_status=false"
    "udev.log_level=3"
    "nowatchdog"
    "amdgpu.gpu_recovery=1"
  ];

  # Nix configuration
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) (
      lib.filterAttrs (name: _: name != "private-config") inputs
    );
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
    # Feed the sops-managed GitHub token to Nix so flake fetches are
    # authenticated (avoids the 60 req/hr unauthenticated rate limit).
    # The template renders the token into a valid nix.conf snippet at runtime.
    extraOptions = "!include /etc/nix/github-access-token.conf";
  };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils
    lshw
    qt6.qtwayland
    sbctl
    openssl
    # python3Packages.python-miio # FIXME: broken in nixpkgs - construct version conflict
  ];

  # Networking
  networking = {
    hostName = "rubi";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.iwd.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
      ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # Boot full-speed direct by default. "client" sets loose reverse-path filtering
  # so that manually toggling an exit node (e.g. the WARP node "pirita" for
  # CGNAT-broken IPv4 sites) works cleanly:
  #   enable:  sudo tailscale set --advertise-exit-node=false --exit-node=pirita --exit-node-allow-lan-access=true
  #   disable: sudo tailscale set --exit-node=
  services.tailscale.useRoutingFeatures = "client";

  # OpenCode server for remote access (Android app + web UI)
  # Binds to 0.0.0.0 but only accessible via Tailscale (trusted interface)
  # UPower for battery reporting
  services.upower.enable = true;

  services.opencode-server = {
    enable = true;
    host = "0.0.0.0";
    port = 4096;
    passwordFile = config.sops.secrets."opencode-server-password".path;
    # Personal API keys only. Work provider/MCP env (inference API, project
    # trackers, wiki, time tracking) is contributed by the customer module
    # (private-config: the active customer's defaults module) and merges here.
    secretEnv = {
      OPENCODE_API_KEY = config.sops.secrets."opencode-api-key".path;
      GITHUB_TOKEN = config.sops.secrets."github-token".path;
    };
  };

  # llama.cpp local inference for OpenCode subagents
  # AMD 680M APU: Vulkan via RADV, shared system memory
  # Models download from HuggingFace on first start (~5GB for qwen2.5-coder-7b)
  services.llama-cpp-server = {
    enable = true;
    model = "bartowski/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M";
    port = 11435;
    host = "127.0.0.1";
    openFirewall = false;
    contextSize = 24576; # 24K context for OpenCode's large system prompts
    gpuLayers = 99;
    modelsDirectory = "/var/lib/llama-cpp";
    extraArgs = [
      "--alias"
      "qwen2.5-coder-7b"
    ];
  };

  # Security
  security.polkit.enable = true;
  services.dbus.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # AMD 680M iGPU: force Mesa radeonsi VA-API/Vulkan drivers explicitly.
  # AMDVLK was discontinued Sept 2025; RADV is the only AMD Vulkan driver.
  # gpu_recovery converts a VCN ring timeout into a controlled GPU reset instead
  # of a hard freeze requiring a reboot.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
  };

  # Audio (PipeWire for modern desktop)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  security.rtkit.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Power management for desktop/laptop
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Backlight control (allows users in video group to control brightness)
  hardware.brillo.enable = true;

  # Printing support
  services.printing.enable = true;

  # Prisma Access Agent VPN + Prisma Browser enables, boot-autostart strip, and
  # VPN state persistence are contributed by the customer module
  # (private-config: the active customer's defaults module).

  # Enable nix-ld for running unpatched binaries
  programs.nix-ld.enable = true;

  # Home Manager configuration for diego
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit (inputs) nix-colors;
      customPkgs = inputs.self.packages."x86_64-linux";
      privateConfig = inputs.private-config or { };
      inherit desktop;
    };
    users.diego = {
      imports = [
        inputs.stylix.homeModules.stylix
        inputs.plasma-manager.homeModules.plasma-manager
        ../../modules/home-manager/colors.nix
        ../../modules/home-manager/fonts.nix
        ../../modules/home-manager/kanshi.nix
        ../../modules/home-manager/monitors.nix
        inputs.ai-tooling.homeManagerModules.opencode-config
        inputs.ai-tooling.homeManagerModules.mcp-config
        inputs.ai-tooling.homeManagerModules.antigravity-config
        inputs.ai-tooling.homeManagerModules.claude-code-config
        inputs.ai-tooling.homeManagerModules.cursor-config
        inputs.ai-tooling.homeManagerModules.ai-skills
        inputs.private-config.homeManagerModules.workMcpConfig
        inputs.private-config.homeManagerModules.workExtras
        ../../home/diego/rubi.nix
      ];
    };
  };

  system.stateVersion = "25.11";

  # Boot optimizations
  # NetworkManager-wait-online blocks the entire boot until network is fully up.
  # On a desktop this is unnecessary - services that need network will wait on
  # their own, and the login screen should not be delayed by network readiness.
  systemd.services.NetworkManager-wait-online.enable = false;

  # Docker: use socket activation instead of starting at boot.
  # The daemon starts on the first docker command (~1s delay on first use).
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  # ModemManager is for 3G/4G/LTE modems - not needed on WiFi-only hardware.
  systemd.services.ModemManager.enable = false;

  # Blacklist the legacy 8250 serial port driver.
  # This machine has no real serial ports; the ttyS0-3 devices enumerated by
  # this driver were showing up as ~6s items in systemd-analyze blame.
  boot.blacklistedKernelModules = [ "8250" ];

  users.users.diego.extraGroups = [ "docker" ];
}
