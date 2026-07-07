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
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix

    # Stylix theming
    inputs.stylix.nixosModules.stylix

    # Core services
    ../common/optional/tailscale.nix
    ./sops.nix # rubi-specific SOPS secrets (minimal for desktop)

    # Impermanence (rubi-specific for desktop)
    ./impermanence.nix

    # Boot configuration (systemd-boot for fast native UEFI boot)
    ./bootloader.nix

    # USB/iOS/device mounting support
    ../common/optional/devices.nix

    # Steam gaming (GameMode, gamescope, Proton-GE) tuned for the 680M APU
    ../common/optional/steam.nix

    # OpenCode remote access (API + web UI)
    ../common/optional/opencode-server.nix

    # Local LLM inference (Vulkan on AMD 680M APU — model cache at /var/lib/llama-cpp)
    ../common/optional/llama-cpp-server.nix

    # libvirt/KVM + virt-manager (Windows 11 VM with virtio-gpu)
    # ../common/optional/virtualization.nix
    inputs.nixvirt.nixosModules.default
    # ./win11-vm.nix

    # Employer security / VPN modules (from private-config)
    inputs.private-config.nixosModules.carbonBlack
    inputs.private-config.nixosModules.nvidiaVpn
    inputs.private-config.nixosModules.atlassianMcpSecrets

    # Prisma Access VPN (employer-specific, from private-config)
    inputs.private-config.nixosModules.prismaAccess

    # Prisma Browser (employer-specific, from private-config)
    inputs.private-config.nixosModules.prismaBrowser
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
  };

  # Enable Sway (provides system-level support: PAM, setuid wrappers, etc.)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # GTK apps use correct theming

    # Export Qt env vars so apps launched from Sway keybindings get the Stylix theme
    extraSessionCommands = ''
      export QT_QPA_PLATFORMTHEME="qt5ct"
      export QT_STYLE_OVERRIDE="kvantum"
      export QT_PLUGIN_PATH="$HOME/.nix-profile/lib/qt-5.15.18/plugins:$HOME/.nix-profile/lib/qt-6/plugins"
      export QML2_IMPORT_PATH="$HOME/.nix-profile/lib/qt-5.15.18/qml:$HOME/.nix-profile/lib/qt-6/qml"
    '';
  };

  # greetd + tuigreet display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # XDG Desktop Portals for wlroots/Sway
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      # The wlr portal needs a "chooser" to pick which output/window to
      # capture. Without it, screencast falls through to uninstalled dmenu
      # programs and reports "no output found", which surfaces in Firefox as
      # `NotAllowedError` on getDisplayMedia(). slurp gives an interactive
      # on-screen output/region selector. This MUST be set here at the NixOS
      # level: xdg.portal.wlr.enable generates the config file and launches
      # the portal with --config=<that file>, which overrides any
      # ~/.config/xdg-desktop-portal-wlr/config from home-manager.
      settings.screencast = {
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        # Cap frame rate; without this the portal may stall on damage-only
        # updates and the consumer sees a frozen stream.
        max_fps = 30;
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = "gtk";
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
    };
  };

  # Keyring for secrets (works with Sway via PAM)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.swaylock = { };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    # System utilities
    pciutils
    usbutils
    lshw
    file-roller
    qt6.qtwayland
    sbctl
    openssl
    # python3Packages.python-miio # FIXME: broken in nixpkgs - construct version conflict
  ];

  # Networking
  networking = {
    hostName = "rubi";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
      ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # OpenCode server for remote access (Android app + web UI)
  # Binds to 0.0.0.0 but only accessible via Tailscale (trusted interface)
  # UPower for battery reporting
  services.upower.enable = true;

  services.opencode-server = {
    enable = true;
    host = "0.0.0.0";
    port = 4096;
    passwordFile = config.sops.secrets."opencode-server-password".path;
    # Load API keys for model providers and MCP servers
    secretEnv = {
      OPENCODE_API_KEY = config.sops.secrets."opencode-api-key".path;
      NVIDIA_API_KEY = config.sops.secrets."nvidia-api-key".path;
      JIRA_BASE_URL = config.sops.secrets."jira-base-url".path;
      JIRA_EMAIL = config.sops.secrets."jira-email".path;
      JIRA_API_KEY = config.sops.secrets."jira-api-key".path;
      CONFLUENCE_BASE_URL = config.sops.secrets."confluence-base-url".path;
      CONFLUENCE_EMAIL = config.sops.secrets."confluence-email".path;
      CONFLUENCE_API_KEY = config.sops.secrets."confluence-api-key".path;
      TRELLO_API_KEY = config.sops.secrets."trello-api-key".path;
      TRELLO_API_TOKEN = config.sops.secrets."trello-api-token".path;
      TEMPO_API_TOKEN = config.sops.secrets."tempo-api-key".path;
      TEMPO_JIRA_API_TOKEN = config.sops.secrets."tempo-jira-api-key".path;
      TEMPO_JIRA_EMAIL = config.sops.secrets."tempo-jira-email".path;
      TEMPO_JIRA_BASE_URL = config.sops.secrets."tempo-jira-base-url".path;
      JIRA_DC_BASE_URL = config.sops.secrets."jira-dc-base-url".path;
      JIRA_DC_EMAIL = config.sops.secrets."jira-dc-email".path;
      JIRA_DC_API_KEY = config.sops.secrets."jira-dc-api-key".path;
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
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
  };
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Backlight control (allows users in video group to control brightness)
  hardware.brillo.enable = true;

  # Printing support
  services.printing.enable = true;

  # Prisma Access Agent VPN (from private-config module)
  # autoStart must stay true to avoid a mkIf bug in the private-config module
  # (setting it false leaves environment.etc."xdg/autostart/PAGui.desktop".source
  # without a value). Instead, strip wantedBy from both services so neither
  # starts at boot. Use `vpn-on` / `vpn-off` to control manually.
  services.prismaAccess = {
    enable = true;
    autoStart = true;
  };
  systemd.services.paa.wantedBy = lib.mkForce [ ];
  systemd.user.services.paa-gui.wantedBy = lib.mkForce [ ];

  # Prisma Browser (from private-config module)
  services.prismaBrowser.enable = true;

  # Enable nix-ld for running unpatched binaries
  programs.nix-ld.enable = true;

  # Home Manager configuration for diego
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit (inputs) nix-colors;
      customPkgs = inputs.self.packages."x86_64-linux";
      privateConfig = inputs.private-config.opencodeConfig or { };
    };
    users.diego = {
      imports = [
        inputs.stylix.homeModules.stylix
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
        inputs.private-config.homeManagerModules.employerMcpConfig
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
