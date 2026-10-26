{ ... }:
{
  flake.modules.nixos.ai-open-webui =
{ config, lib, pkgs, ... }:

{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    # 8080 is qbittorrent's webui and 8081 is calibre-server; open-webui lost
    # the race for 8080 and failed to start. 8082/8083/8086 are also taken
    # (homepage, calibre-web, miniflux).
    port = 8088;
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
}  ;
}
