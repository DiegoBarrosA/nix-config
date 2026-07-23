# Ollama with Vulkan GPU acceleration for AMD GPUs
# Works on all AMD GPUs via RADV Mesa driver (including legacy GCN4/Polaris).
#
# Unlike ROCm which dropped gfx803 support after ROCm 4.5,
# Vulkan via RADV works reliably on all AMD GPUs with modern Mesa.
#
# Usage:
#   services.ollama-vulkan = {
#     enable = true;
#     loadModels = [ "qwen2.5-coder:7b" ];
#   };
#
# API endpoint: http://localhost:11434/v1 (OpenAI-compatible)

{ config, lib, pkgs, ... }:

let
  cfg = config.services.ollama-vulkan;
in
{
  options.services.ollama-vulkan = {
    enable = lib.mkEnableOption "Ollama LLM server with Vulkan GPU acceleration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ollama-vulkan;
      defaultText = lib.literalExpression "pkgs.ollama-vulkan";
      description = "The Ollama package to use (should be Vulkan-enabled).";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind the server to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port for the Ollama API.";
    };

    loadModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "qwen2.5-coder:7b" "qwen2.5:14b" ];
      description = ''
        Models to auto-download after the server starts.
        Uses ollama pull under the hood. Model names from: https://ollama.com/library
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall port for the server.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      inherit (cfg) package loadModels openFirewall;
      host = cfg.host;
      port = cfg.port;
      user = "ollama";
      group = "ollama";
      environmentVariables = {
        OLLAMA_ORIGINS = "*";
      };
    };

    # The NixOS module's DynamicUser + sandboxing conflicts with impermanence
    # mounts and Vulkan GPU device access. Strip sandboxing entirely — the
    # service runs as a static user with minimal privileges anyway.
    systemd.services.ollama = {
      serviceConfig = lib.mkForce {
        Type = "exec";
        ExecStart = "${cfg.package}/bin/ollama serve";
        WorkingDirectory = "/var/lib/ollama";
        StateDirectory = "ollama";
        StateDirectoryMode = "0755";
        User = "ollama";
        Group = "ollama";
        DynamicUser = false;
        Restart = "on-failure";
        RestartSec = 5;
        # No sandboxing — Vulkan GPU + impermanence need open access
        ProtectSystem = lib.mkForce false;
        ProtectHome = lib.mkForce false;
        PrivateDevices = lib.mkForce false;
        PrivateTmp = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        ProtectKernelTunables = lib.mkForce false;
        ProtectKernelModules = lib.mkForce false;
        ProtectKernelLogs = lib.mkForce false;
        ProtectClock = lib.mkForce false;
        ProtectControlGroups = lib.mkForce false;
        RestrictNamespaces = lib.mkForce false;
        RestrictSUIDSGID = lib.mkForce false;
        LockPersonality = lib.mkForce false;
        MemoryDenyWriteExecute = lib.mkForce false;
        SystemCallArchitectures = lib.mkForce false;
        RemoveIPC = lib.mkForce false;
        CapabilityBoundingSet = lib.mkForce null;
        SystemCallFilter = lib.mkForce null;
        RestrictAddressFamilies = lib.mkForce null;
        DeviceAllow = lib.mkForce null;
      };
      environment = lib.mkForce {
        HOME = "/var/lib/ollama";
        OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        OLLAMA_MODELS = "/var/lib/ollama/models";
        OLLAMA_ORIGINS = "*";
        # Vulkan GPU detection — systemd services don't inherit session variables
        VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
        AMD_VULKAN_ICD = "RADV";
        # AMD 680M is an iGPU — ollama drops integrated GPUs by default
        OLLAMA_IGPU_ENABLE = "1";
        # OpenCode sends ~13k tokens of system prompt + tools per request.
        # Default 4096 context truncates everything. 32k fits comfortably
        # in the 680M's 16 GB shared VRAM alongside the 14B model (~9 GB).
        OLLAMA_CONTEXT_LENGTH = "32768";
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    # Ensure diego can access ollama models
    users.users.diego.extraGroups = [ "ollama" ];
  };
}
