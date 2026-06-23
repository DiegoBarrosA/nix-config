# llama.cpp server with Vulkan backend for AMD GPUs (including legacy GCN4/Polaris like RX580)
# Provides an OpenAI-compatible API for LLM inference with full GPU acceleration
#
# Unlike ROCm which dropped support for gfx803 (Polaris) after ROCm 4.5,
# Vulkan via RADV works reliably on all AMD GPUs with modern Mesa.
#
# Usage:
#   services.llama-cpp-server = {
#     enable = true;
#     model = "bartowski/Qwen2.5-7B-Instruct-GGUF:Q4_K_M";  # HuggingFace format
#   };
#
# API endpoint: http://localhost:11435/v1/chat/completions (OpenAI-compatible)

{ config, lib, pkgs, ... }:

let
  cfg = config.services.llama-cpp-server;
in
{
  options.services.llama-cpp-server = {
    enable = lib.mkEnableOption "llama.cpp server with Vulkan GPU acceleration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp-vulkan;
      defaultText = lib.literalExpression "pkgs.llama-cpp-vulkan";
      description = "The llama.cpp package to use (should be Vulkan-enabled).";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host address to bind the server to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11435;
      description = "Port for the llama.cpp server API.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      description = ''
        Model to load. Can be:
        - HuggingFace format: "owner/repo:quantization" (e.g., "bartowski/Qwen2.5-7B-Instruct-GGUF:Q4_K_M")
        - Local path: "/path/to/model.gguf"
        
        For 8GB VRAM (RX580), recommended quantizations:
        - 7B models: Q4_K_M (~4.5GB) or Q5_K_M (~5GB)
        - 3B models: Q8_0 (~3.5GB) for maximum quality
      '';
      example = "bartowski/Qwen2.5-7B-Instruct-GGUF:Q4_K_M";
    };

    modelsDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/nix/storage/llm/models";
      description = "Directory for storing/caching downloaded models.";
    };

    gpuLayers = lib.mkOption {
      type = lib.types.oneOf [ lib.types.int (lib.types.enum [ "-1" "auto" ]) ];
      default = "auto";
      description = ''
        Number of model layers to offload to GPU.
        "auto" or -1: let llama.cpp automatically determine based on available VRAM.
        99: offload all layers (only works if model + context fits in VRAM).
        Lower values split between CPU and GPU (useful if VRAM is limited).
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = ''
        Context window size in tokens.
        Higher values use more VRAM. For 8GB VRAM:
        - 7B Q4: ~8192 context fits comfortably
        - 7B Q4: ~16384 context is tight
        - 3B Q8: ~16384 context fits well
      '';
    };

    flashAttention = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable flash attention for reduced VRAM usage and better performance.
        Works with most modern model architectures (Llama, Mistral, Qwen, etc.).
      '';
    };

    vulkanDevice = lib.mkOption {
      type = lib.types.str;
      default = "Vulkan0";
      description = ''
        Vulkan device to use. "Vulkan0" is the first GPU detected.
        For multi-GPU setups, can specify multiple: "Vulkan0,Vulkan1".
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional arguments to pass to llama-server.";
      example = [ "--temp" "0.7" "--top-p" "0.9" ];
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open the firewall port for the server.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "llama";
      description = "User account under which llama-server runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "llama";
      description = "Group under which llama-server runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create dedicated user/group for the service
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ "video" "render" ];  # Required for GPU access
      home = cfg.modelsDirectory;
      description = "llama.cpp server user";
    };

    users.groups.${cfg.group} = { };

    # Systemd service
    systemd.services.llama-cpp-server = {
      description = "llama.cpp LLM Server (Vulkan GPU Acceleration)";
      after = [ "network.target" "local-fs.target" "gpu-setup.service" ];
      wants = [ "gpu-setup.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ cfg.package pkgs.curl ];  # curl needed for HF downloads

      environment = {
        # Vulkan device selection
        GGML_VULKAN_DEVICE = "0";
        # Ensure Vulkan uses RADV (AMD's open-source Vulkan driver)
        AMD_VULKAN_ICD = "RADV";
        # Model cache directory for HuggingFace downloads
        HF_HOME = "${cfg.modelsDirectory}/huggingface";
        HF_HUB_CACHE = "${cfg.modelsDirectory}/huggingface/hub";
        # Mesa shader cache (for Vulkan)
        MESA_SHADER_CACHE_DIR = "${cfg.modelsDirectory}/.cache/mesa";
        RADV_PERFTEST = "gpl";  # Enable graphics pipeline library for faster shader compilation
        # Home directory for the service
        HOME = cfg.modelsDirectory;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        
        # Build the command with all options
        ExecStart = let
          flashAttnArg = if cfg.flashAttention then "--flash-attn on" else "";
          modelArg = if lib.hasPrefix "/" cfg.model
            then "-m ${cfg.model}"
            else "-hf ${cfg.model}";
          extraArgsStr = lib.concatStringsSep " " cfg.extraArgs;
        in ''
          ${cfg.package}/bin/llama-server \
            --host ${cfg.host} \
            --port ${toString cfg.port} \
            -dev ${cfg.vulkanDevice} \
            -ngl ${toString cfg.gpuLayers} \
            ${flashAttnArg} \
            ${modelArg} \
            --ctx-size ${toString cfg.contextSize} \
            -t -1 \
            ${extraArgsStr}
        '';

        Restart = "on-failure";
        RestartSec = 10;

        # Allow GPU device access
        PrivateDevices = false;
        DeviceAllow = [
          "/dev/dri/renderD128 rw"
          "/dev/dri/card0 rw"
        ];
        SupplementaryGroups = [ "video" "render" ];

        # Security hardening (where possible)
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ cfg.modelsDirectory ];
        PrivateTmp = true;

        # Resource limits
        LimitNOFILE = 65536;
        
        # Working directory for model downloads
        WorkingDirectory = cfg.modelsDirectory;
      };
    };

    # Ensure models directory exists with correct permissions.
    # The "z" line fixes ownership on existing directories (e.g. created as root:root
    # by the impermanence module before the llama user was configured).
    systemd.tmpfiles.rules = [
      "z ${cfg.modelsDirectory} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.modelsDirectory} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.modelsDirectory}/huggingface 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.modelsDirectory}/huggingface/hub 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.modelsDirectory}/.cache 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.modelsDirectory}/.cache/mesa 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.modelsDirectory}/.cache/llama.cpp 0755 ${cfg.user} ${cfg.group} -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    # Ensure Vulkan tools are available for debugging
    environment.systemPackages = [ pkgs.vulkan-tools ];
  };
}
