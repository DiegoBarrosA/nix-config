{ config, lib, pkgs, ... }:

{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    openFirewall = true;

    environment = {

      ENABLE_OLLAMA_API = "False";

      OPENAI_API_BASE_URL = "http://127.0.0.1:11435";
      OPENAI_API_KEY = "sk-no-key-required";
      ENABLE_OPENAI_API = "True";

      WEBUI_NAME = "Cobalto LLM Hub";
      ENABLE_SIGNUP = "True";
      WEBUI_AUTH = "True";

      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
  };
}