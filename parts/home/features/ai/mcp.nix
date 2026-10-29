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

    # Defined but off by default (enabled = false); turn on per session.
    zennotes = {
      enable = true;
      autostart = false;
    };

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

  # Off by default in every client (jira-dc, netsuite, trello are already
  # disabled in the private config).
  programs.mcp.servers.jsm-forms.enabled = false;

  # Work secrets for the Jira/Confluence/Tempo/JSM/Trello MCPs, sourced by
  # nushell (cli/nushell.nix). Generated from the private repo's secretEnv so
  # new instances/secrets appear here without hand-editing. Prefix filter keeps
  # inference keys (ANTHROPIC_API_KEY etc.) out of every shell: exporting those
  # would flip Claude Code from login auth to API-key billing.
  #
  # A home.file (not an activation script) so the file is part of the
  # generation: nushell's `source` needs it at parse time, and a half-run
  # activation used to leave it missing. Content is only secret *paths*, read
  # at shell start, so a store symlink is safe.
  home.file.".config/nushell/mcp-env.nu" =
    let
      mcpPrefixes = [ "WORK_" "JIRA_" "CONFLUENCE_" "JSM_" "TRELLO_" "TEMPO_" ];
      isMcp = name: lib.any (p: lib.hasPrefix p name) mcpPrefixes;
      secretEnv = lib.filterAttrs (n: _: isMcp n) (privateConfig.workSecretEnv or { });
    in
    {
      force = true; # replace the old activation-written regular file
      text =
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (n: path: ''
            if ("${path}" | path exists) { $env.${n} = (open ${path} | str trim) }'') secretEnv
        )
        + "\n";
    };
};
}
