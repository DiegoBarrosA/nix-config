{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.mcp-config = {
    enable = true;
    mcpNixos.enable = true;
    github = {
      enable = true;
      # The mcp-config module invokes the binary with no subcommand, which just
      # prints usage and exits. opencode then spends ~1s per start waiting on a
      # server that was never going to speak MCP before giving up ("server
      # unavailable key=github"), which is most of its cold-start time. Wrap the
      # package so `stdio` is always passed. Drop this once nix-ai-tooling grows
      # an args option for the github server.
      package = pkgs.writeShellScriptBin "github-mcp-server" ''
        exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio "$@"
      '';
    };
    playwright = {
      enable = true;
      browserPath = "${pkgs.firefox-devedition}/bin/firefox";
    };
    thunderbird = {
      enable = true;
      autostart = false; # lazily disabled — rarely used; enable on demand
    };
    zennotes = {
      enable = true;
      # cliPath defaults to ~/.config/ZenNotes/cli/zen
    };
    supermercados = {
      enable = true;
      autostart = false; # defined but off by default; enable per-session from the MCP menu
    };
  };

  # mcp-env.nu template + deprecated-syntax fix (moved from rubi.nix)
  home.activation.copyMcpEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        MCP_ENV_FILE="$HOME/.config/nushell/mcp-env.nu"

        # Fix deprecated let-env syntax in existing file
        if [ -f "$MCP_ENV_FILE" ]; then
          sed -i 's/^let-env \([A-Z_]*\) = /\$env.\1 = /g' "$MCP_ENV_FILE"
        else
          mkdir -p "$(dirname "$MCP_ENV_FILE")"
          cat > "$MCP_ENV_FILE" << 'EOF'
    # MCP Environment Variables
    # Uncomment and fill in your credentials below
    # This file is sourced by nushell on startup

    # Jira Cloud MCP — named instances (assembled into JIRA_INSTANCES by the wrapper)
    if ("/run/secrets/work-jira-a-base-url" | path exists) {
      $env.WORK_JIRA_A_BASE_URL = (open /run/secrets/work-jira-a-base-url | str trim)
      $env.WORK_JIRA_A_EMAIL    = (open /run/secrets/work-jira-a-email    | str trim)
      $env.WORK_JIRA_A_API_KEY  = (open /run/secrets/work-jira-a-api-key  | str trim)
    }
    if ("/run/secrets/work-jira-b-base-url" | path exists) {
      $env.WORK_JIRA_B_BASE_URL = (open /run/secrets/work-jira-b-base-url | str trim)
      $env.WORK_JIRA_B_EMAIL    = (open /run/secrets/work-jira-b-email    | str trim)
      $env.WORK_JIRA_B_API_KEY  = (open /run/secrets/work-jira-b-api-key  | str trim)
    }
    if ("/run/secrets/work-jira-c-base-url" | path exists) {
      $env.WORK_JIRA_C_BASE_URL = (open /run/secrets/work-jira-c-base-url | str trim)
      $env.WORK_JIRA_C_EMAIL    = (open /run/secrets/work-jira-c-email    | str trim)
      $env.WORK_JIRA_C_API_KEY  = (open /run/secrets/work-jira-c-api-key  | str trim)
    }
    if ("/run/secrets/work-jira-d-base-url" | path exists) {
      $env.WORK_JIRA_D_BASE_URL = (open /run/secrets/work-jira-d-base-url | str trim)
      $env.WORK_JIRA_D_EMAIL    = (open /run/secrets/work-jira-d-email    | str trim)
      $env.WORK_JIRA_D_API_KEY  = (open /run/secrets/work-jira-d-api-key  | str trim)
    }

    # Confluence Cloud MCP — named instances (assembled into CONFLUENCE_INSTANCES by the wrapper)
    if ("/run/secrets/confluence-main-base-url" | path exists) {
      $env.CONFLUENCE_BASE_URL     = (open /run/secrets/confluence-main-base-url | str trim)
      $env.CONFLUENCE_EMAIL        = (open /run/secrets/confluence-main-email    | str trim)
      $env.CONFLUENCE_API_KEY      = (open /run/secrets/confluence-main-api-key  | str trim)
      $env.WORK_CONFLUENCE_A_BASE_URL = (open /run/secrets/confluence-main-base-url | str trim)
      $env.WORK_CONFLUENCE_A_EMAIL    = (open /run/secrets/confluence-main-email    | str trim)
      $env.WORK_CONFLUENCE_A_API_KEY  = (open /run/secrets/confluence-main-api-key  | str trim)
    }
    if ("/run/secrets/work-confluence-b-base-url" | path exists) {
      $env.WORK_CONFLUENCE_B_BASE_URL = (open /run/secrets/work-confluence-b-base-url | str trim)
      $env.WORK_CONFLUENCE_B_EMAIL    = (open /run/secrets/work-confluence-b-email    | str trim)
      $env.WORK_CONFLUENCE_B_API_KEY  = (open /run/secrets/work-confluence-b-api-key  | str trim)
    }

    # Jira Data Center MCP
    if ("/run/secrets/jira-dc-base-url" | path exists) {
      $env.JIRA_DC_BASE_URL = (open /run/secrets/jira-dc-base-url | str trim)
      $env.JIRA_DC_EMAIL    = (open /run/secrets/jira-dc-email    | str trim)
      $env.JIRA_DC_API_KEY  = (open /run/secrets/jira-dc-api-key  | str trim)
    }

    # ===== OpenClaw Configuration =====
    # Gateway authentication token (generate a random string)
    # $env.OPENCLAW_GATEWAY_TOKEN = "your-gateway-token"

         # Hugging Face Inference API (free tier)
         # Get token from: https://huggingface.co/settings/tokens/new
         # Required permission: "Make calls to Inference Providers"
         # $env.HUGGINGFACE_HUB_TOKEN = "hf_your-token"
         # Alternative env var name also works:
         # $env.HF_TOKEN = "hf_your-token"

         # Optional: Telegram bot token (from @BotFather)
         # $env.OPENCLAW_TELEGRAM_TOKEN = "your-telegram-bot-token"

          # Tempo Worklog MCP — sourced from SOPS secrets at /run/secrets/
          if ("/run/secrets/tempo-jira-base-url" | path exists) {
            $env.TEMPO_JIRA_BASE_URL  = (open /run/secrets/tempo-jira-base-url  | str trim)
            $env.TEMPO_JIRA_EMAIL     = (open /run/secrets/tempo-jira-email      | str trim)
            $env.TEMPO_JIRA_API_TOKEN = (open /run/secrets/tempo-jira-api-key    | str trim)
            $env.TEMPO_API_TOKEN      = (open /run/secrets/tempo-api-key         | str trim)
          }
    EOF
          chmod 600 "$MCP_ENV_FILE"
        fi
  '';
}
