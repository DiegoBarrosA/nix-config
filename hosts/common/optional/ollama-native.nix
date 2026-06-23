{ config, lib, pkgs, ... }:

{
  # Native Ollama service for LLM inference
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    package = pkgs.ollama-rocm;
    # acceleration = "rocm";  # Disabled due to clblast build issues on remote
    # acceleration = null;  # CPU-only mode for now
    environmentVariables = {
      # HSA_OVERRIDE_GFX_VERSION = "8.0.3";  # For RX580 - disabled
      OLLAMA_ORIGINS = "*";  # Allow CORS from any origin
    };
    # Ollama will store models in /var/lib/private/ollama by default
  };

  # Open firewall for Ollama
  networking.firewall.allowedTCPPorts = [ 11434 ];

  # Fix /var/lib/private permissions for systemd DynamicUser
  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
  ];

  # Note: Persistence is already configured in impermanence.nix as /var/lib/ollama
  # The actual path is /var/lib/private/ollama due to systemd DynamicUser=true
  # We should NOT add it here to avoid conflicts with StateDirectory

  # Ensure diego can access ollama
  users.users.diego.extraGroups = [ "ollama" ];
}
