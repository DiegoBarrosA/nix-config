{ ... }:
{
  flake.modules.homeManager.ai-mcp =
{
  config,
  lib,
  pkgs,
  privateConfig ? { },
  ...
}:
{
  programs.mcp-config = {
    enable = true;

    # Core MCPs (always active, low overhead)
    mcpNixos.enable = true;

    zennotes.enable = true;

    # Heavy MCPs (tools disabled globally, enabled via subagents)
    github = {
      enable = true;
      # Nothing exports GITHUB_TOKEN, so the client passes an empty token. Read the sops secret directly.
      package = pkgs.writeShellScriptBin "github-mcp-server" ''
        if [ -z "''${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ] && [ -r /run/secrets/github-token ]; then
          GITHUB_PERSONAL_ACCESS_TOKEN="$(< /run/secrets/github-token)"
          export GITHUB_PERSONAL_ACCESS_TOKEN
        fi
        exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio "$@"
      '';
    };

    playwright = {
      enable = true;
      browser = "chromium";
      browserPath = "${pkgs.chromium}/bin/chromium";
      userDataDir = "${config.home.homeDirectory}/.config/playwright-chromium-profile";
    };

    # Optional MCPs (disabled by default)
    supermercados = {
      enable = false;
      autostart = false;
    };
  };

  # Work secrets for the Jira/Confluence/Tempo/JSM/Trello MCPs, sourced by
  # nushell (cli/nushell.nix). Generated from the private repo's secretEnv so
  # new instances/secrets appear here without hand-editing. Prefix filter keeps
  # inference keys (ANTHROPIC_API_KEY etc.) out of every shell: exporting those
  # would flip Claude Code from login auth to API-key billing.
  home.activation.copyMcpEnv =
    let
      mcpPrefixes = [ "WORK_" "JIRA_" "CONFLUENCE_" "JSM_" "TRELLO_" "TEMPO_" ];
      isMcp = name: lib.any (p: lib.hasPrefix p name) mcpPrefixes;
      secretEnv = lib.filterAttrs (n: _: isMcp n) (privateConfig.workSecretEnv or { });
      mcpEnvFile = pkgs.writeText "mcp-env.nu" (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (n: path: ''
            if ("${path}" | path exists) { $env.${n} = (open ${path} | str trim) }'') secretEnv
        )
        + "\n"
      );
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      MCP_ENV_FILE="$HOME/.config/nushell/mcp-env.nu"
      mkdir -p "$(dirname "$MCP_ENV_FILE")"
      install -m 600 ${mcpEnvFile} "$MCP_ENV_FILE"
    '';
};
}
