{ ... }:
{
  flake.modules.nixos.ai-litellm =
{ config, ... }:

let
  # OpenCode Go serves Kimi and GLM as OpenAI chat under /v1 (see hermes-agent.nix).
  go = model: {
    model = "openai/${model}";
    api_base = "https://opencode.ai/zen/go/v1";
    api_key = "os.environ/OPENCODE_GO_API_KEY";
  };
  nim = model: {
    model = "openai/${model}";
    api_base = "https://integrate.api.nvidia.com/v1";
    api_key = "os.environ/NVIDIA_API_KEY";
  };
in
{
  # One local endpoint for every model call on cobalto, with two groups:
  # personal is OpenCode Go only, because Hermes reads the whole vault and free
  # tiers may train on prompts. public is Go first, then free tiers, for public
  # repos only. No database: no budgets or key management yet, so nothing in
  # stateDir needs to survive a reboot.
  services.litellm = {
    enable = true;
    host = "127.0.0.1";
    port = 4000;
    environmentFile = config.sops.templates."litellm.env".path;
    settings = {
      model_list = [
        { model_name = "personal"; litellm_params = go "kimi-k3"; }
        # One group with an order, not a fallback to a second group: LiteLLM
        # does not cool down a group's only deployment, so a fallback chain
        # called the limited Go key again on every request (tested locally).
        { model_name = "public"; litellm_params = go "kimi-k3" // { order = 1; }; }
        { model_name = "public"; litellm_params = nim "nvidia/nemotron-3-ultra-550b-a55b" // { order = 2; }; }
      ];
      # personal has one deployment and no fallback, so it fails when Go is
      # limited, on purpose. In public a failed deployment cools for 30 minutes
      # and the one retry goes to the next deployment by order.
      router_settings = {
        num_retries = 1;
        allowed_fails = 0;
        cooldown_time = 1800;
        enable_pre_call_checks = true;
      };
      # Providers reject parameters they do not know; drop them instead.
      litellm_settings.drop_params = true;
      general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
    };
  };

  sops.secrets."litellm-master-key" = { };
  sops.templates."litellm.env" = {
    content = ''
      LITELLM_MASTER_KEY=${config.sops.placeholder."litellm-master-key"}
      OPENCODE_GO_API_KEY=${config.sops.placeholder."opencode-api-key"}
      NVIDIA_API_KEY=${config.sops.placeholder."hermes-nvidia-api-key"}
    '';
    restartUnits = [ "litellm.service" ];
  };
}
  ;
}
