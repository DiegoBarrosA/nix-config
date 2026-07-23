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
    mcpTelegram.enable = true;
    jobspy = {
      enable = true;
      autostart = false; # lazily disabled — rarely used; enable on demand
    };
    github.enable = true;
    playwright = {
      enable = true;
      browserPath = "${pkgs.firefox-devedition}/bin/firefox";
    };
    thunderbird = {
      enable = true;
      autostart = false; # lazily disabled — rarely used; enable on demand
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

    # Jira Cloud MCP
    # $env.JIRA_BASE_URL = "https://your-domain.atlassian.net"
    # $env.JIRA_EMAIL = "your-email@example.com"
    # $env.JIRA_API_KEY = "your-api-key"

    # Confluence Cloud MCP
    # $env.CONFLUENCE_BASE_URL = "https://your-domain.atlassian.net"
    # $env.CONFLUENCE_EMAIL = "your-email@example.com"
    # $env.CONFLUENCE_API_KEY = "your-api-key"

    # Jira Data Center MCP (disabled - no tools implemented)
    # $env.JIRA_DC_BASE_URL = "https://jira.your-company.com"
    # $env.JIRA_DC_EMAIL = "your-email@example.com"
    # $env.JIRA_DC_API_KEY = "your-api-key"

    # Obsidian REST API
    # $env.OBSIDIAN_API_KEY = "your-obsidian-api-key"

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

     # simple-telegram-mcp (MTProto - from https://my.telegram.org/apps)
          # $env.TELEGRAM_API_ID = "your-api-id"
          # $env.TELEGRAM_API_HASH = "your-api-hash"

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
