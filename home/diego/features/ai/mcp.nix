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

      package = pkgs.writeShellScriptBin "github-mcp-server" ''
        exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio "$@"
      '';
    };
    playwright = {
      enable = true;
      browserPath = "${pkgs.firefox-devedition}/bin/firefox-devedition";

      userDataDir = "${config.home.homeDirectory}/.config/playwright-firefox-profile";
    };
    thunderbird = {
      enable = true;
      autostart = false;
    };
    zennotes = {
      enable = true;

    };
    supermercados = {
      enable = true;
      autostart = false;
    };
  };

  home.activation.copyMcpEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        MCP_ENV_FILE="$HOME/.config/nushell/mcp-env.nu"

        if [ -f "$MCP_ENV_FILE" ]; then
          sed -i 's/^let-env \([A-Z_]*\) = /\$env.\1 = /g' "$MCP_ENV_FILE"
        else
          mkdir -p "$(dirname "$MCP_ENV_FILE")"
          cat > "$MCP_ENV_FILE" << 'EOF'

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

    if ("/run/secrets/jira-dc-base-url" | path exists) {
      $env.JIRA_DC_BASE_URL = (open /run/secrets/jira-dc-base-url | str trim)
      $env.JIRA_DC_EMAIL    = (open /run/secrets/jira-dc-email    | str trim)
      $env.JIRA_DC_API_KEY  = (open /run/secrets/jira-dc-api-key  | str trim)
    }

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
