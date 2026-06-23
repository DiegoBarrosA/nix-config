# Open-WebUI - Native NixOS service for LLM chat interface
# Connects to llama-cpp-server via OpenAI-compatible API
{ config, lib, pkgs, ... }:

{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    openFirewall = true;

    environment = {
      # Disable Ollama integration - we use llama-cpp-server instead
      ENABLE_OLLAMA_API = "False";

      # Connect to llama-cpp-server via OpenAI-compatible API
      OPENAI_API_BASE_URL = "http://127.0.0.1:11435";
      OPENAI_API_KEY = "sk-no-key-required";
      ENABLE_OPENAI_API = "True";

      # UI settings
      WEBUI_NAME = "Cobalto LLM Hub";
      ENABLE_SIGNUP = "True"; # First user becomes admin
      WEBUI_AUTH = "True";

      # Telemetry disabled by default in NixOS module, but be explicit
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
  };
}