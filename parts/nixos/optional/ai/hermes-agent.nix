{ inputs, ... }:
{
  flake.modules.nixos.ai-hermes-agent =
{ config, lib, pkgs, ... }:

let
  cfg = config.services.hermes-agent;
  vault = "/srv/media/Obsidian/obsidiana";
  # Hermes may write only here. The rest of the vault is read-only for it.
  scratch = "${vault}/Hermes";

  # One ACP wrapper per Claude account that has a token. Hermes picks the
  # account by name: delegate_task with acp_command set to the wrapper's path.
  # Each wrapper keeps its own Claude config dir under the hermes state dir and
  # reads the token (group hermes, mode 0440) at start, so no token is in the store.
  claudeCfg = config.home-manager.users.diego.programs.claude-code-config;
  claudeAccounts = lib.filterAttrs (_: p: p.tokenFile != null) claudeCfg.profiles;
  claudeWrapper =
    name: p:
    pkgs.writeShellScriptBin "hermes-claude-${name}" ''
      token="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < ${lib.escapeShellArg p.tokenFile} 2>/dev/null || true)"
      if [ -z "$token" ]; then
        echo "hermes-claude-${name}: token file ${p.tokenFile} missing, empty or unreadable by $(${pkgs.coreutils}/bin/id -un)" >&2
        exit 1
      fi
      export CLAUDE_CODE_OAUTH_TOKEN="$token"
      export CLAUDE_CONFIG_DIR=${cfg.stateDir}/claude/${name}
      ${pkgs.coreutils}/bin/mkdir -p "$CLAUDE_CONFIG_DIR"
      exec ${claudeCfg.acpPackage}/bin/claude-agent-acp "$@"
    '';
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  services.hermes-agent = {
    enable = true;
    environmentFiles = [ config.sops.templates."hermes.env".path ];

    # Not a secret, so it may live in the Nix store. A non-loopback public URL
    # turns on the dashboard login gate (basic auth, set in hermes.env) even
    # though the backend binds loopback behind nginx. The dashboard also
    # accepts this hostname as the Host header.
    environment.HERMES_DASHBOARD_PUBLIC_URL = "https://hermes.minerales.network";
    environment.OBSIDIAN_VAULT_PATH = vault;

    # OpenCode Go (paid subscription, key in opencode-api-key). If the key
    # expires the endpoint answers 401 api_key_expired, and Zen then silently
    # treats requests as free-tier (429 FreeUsageLimitError).
    settings.model = {
      provider = "opencode-go";
      default = "kimi-k3";
    };

    # Chain: another Go model, then hosted NIM, then the local llama.cpp
    # server (no quota). NIM: /v1/models lists models the key cannot call;
    # nemotron-3-super-120b-a12b, kimi-k2.6 and two others returned 404 "Function
    # not found for account", while nemotron-3-ultra-550b-a55b and
    # minimax-m3.1-flash returned 200 (2026-10-28), so re-test before changing
    # ids. OpenCode Zen is left out: its free tier makes Hermes wait 600 s per
    # retry once capped.
    settings.fallback_providers = [
      {
        provider = "opencode-go";
        model = "glm-5.3";
      }
      {
        provider = "nvidia";
        model = "nvidia/nemotron-3-ultra-550b-a55b";
      }
      {
        provider = "custom";
        model = "Llama-3.2-3B-Instruct-Q8_0";
        base_url = "http://127.0.0.1:11435/v1";
      }
    ];

    backend.mode = "dashboard";


    # GitHub access goes through an MCP server, so the token never enters the
    # agent's shell. Hermes blocks GH_TOKEN and GITHUB_TOKEN from every shell
    # subprocess (Tier-1 secrets) and refuses them in env_passthrough, so the
    # shell cannot use the token. The server process gets it because Hermes
    # expands ${GH_TOKEN} from its own environment (hermes.env) when it
    # connects. The literal ${GH_TOKEN} is what lands in config.yaml, not the
    # value. Read-only: drop --read-only to let it push and open PRs.
    # By default Hermes hides MCP tools behind tool_search / tool_describe /
    # tool_call, and tool_call needs nested {name, arguments} entries. Kimi K3
    # dropped the arguments through that bridge, so GitHub's tools are
    # exposed directly instead. The 1M-token context absorbs the extra schemas.
    settings.tools.tool_search.enabled = "off";

    mcpServers.github = {
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      args = [ "stdio" "--read-only" "--toolsets" "repos,issues,pull_requests" ];
      env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GH_TOKEN}";
    };
  };


  # Terminal TUI for diego, run as the install owner. The hermes install state
  # is writable only by the hermes user, so a plain `hermes` as diego fails on
  # .install.lock. The wrapper sets HERMES_HOME, so sudo needs no env passthrough.
  # rubi runs it as: ssh -t cobalto sudo -u hermes /run/current-system/sw/bin/hermes-tui
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "hermes-tui" ''
      export HERMES_HOME=${cfg.stateDir}/.hermes
      exec ${cfg.package}/bin/hermes --tui "$@"
    '')
  ]
  ++ lib.mapAttrsToList claudeWrapper claudeAccounts;

  # Names only, no secrets. Read by Hermes (or Diego) to pick an account.
  environment.etc."hermes/claude-accounts.md".text =
    ''
      # Claude accounts for Hermes

      To use account X, call delegate_task with acp_command set to its wrapper.

    ''
    + lib.concatMapStrings (n: "- ${n}: /run/current-system/sw/bin/hermes-claude-${n}\n") (
      lib.attrNames claudeAccounts
    );

  security.sudo.extraRules = [
    {
      users = [ "diego" ];
      runAs = cfg.user;
      commands = [
        {
          command = "/run/current-system/sw/bin/hermes-tui";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # System git config, applied because the service HOME is /var/lib/hermes
  # (no ~/.gitconfig). Identity only: git in the shell has no GitHub
  # credentials (see the MCP server above), so it clones public repos.
  programs.git = {
    enable = true;
    config.user = {
      name = "Hermes";
      email = "hermes@minerales.network";
    };
  };

  # /var/lib/hermes is an impermanence bind mount. It hides the workspace that
  # activation made, and the backend started before tmpfiles recreated it
  # (status=200/CHDIR), which failed the switch. Wait for the mount and create
  # the directory as root before the unit changes into it.
  systemd.services.hermes-backend = {
    unitConfig.RequiresMountsFor = [ cfg.stateDir ];
    serviceConfig.ExecStartPre = "+${pkgs.coreutils}/bin/install -d -o ${cfg.user} -g ${cfg.group} -m 2770 ${cfg.workingDirectory}";
  };

  # ProtectSystem=strict makes /srv read-only for the units. Open the
  # scratch folder only, for the gateway and for the dashboard's chat TUI.
  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = [ scratch ];
  systemd.services.hermes-backend.serviceConfig.ReadWritePaths = [ scratch ];

  # POSIX ACLs, because the vault belongs to diego (Syncthing) and the parents
  # to media. hermes gets traverse on the parents, read on the vault, and
  # read-write on Hermes/. The default entries (d:) cover files Syncthing adds
  # later. diego keeps rwX on Hermes/ so Syncthing can sync what hermes wrote
  # (the unit runs with UMask 0007, so those files are hermes-owned).
  #
  # This is a oneshot the units depend on, not a tmpfiles rule: a unit with
  # ReadWritePaths fails with 226/NAMESPACE when the path is missing, and
  # tmpfiles does not run again when the unit restarts, so it looped forever.
  systemd.services.hermes-vault-access = {
    description = "Create the Hermes scratch folder and set its ACLs in the vault";
    unitConfig.RequiresMountsFor = [ vault ];
    path = [ pkgs.acl pkgs.coreutils pkgs.findutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      setfacl -m u:${cfg.user}:--x /srv/media /srv/media/Obsidian
      install -d -o diego -g users -m 0775 ${scratch}
      setfacl -R -m u:${cfg.user}:rX ${vault}
      find ${vault} -type d -exec setfacl -m d:u:${cfg.user}:rX {} +
      setfacl -R -m u:${cfg.user}:rwX,u:diego:rwX ${scratch}
      find ${scratch} -type d -exec setfacl -m d:u:${cfg.user}:rwX,d:u:diego:rwX {} +
    '';
  };

  # The module copies environmentFiles into .env in an activation script. On
  # this host sops renders secrets later, in sops-install-secrets.service, so
  # that copy always held the previous render (a secret added in one deploy
  # showed up only after the next). EnvironmentFile= reads the rendered file at
  # unit start instead, and restartUnits on the template restarts the units
  # after each render. The .env copy stays as a harmless duplicate.
  systemd.services.hermes-agent = {
    requires = [ "hermes-vault-access.service" ];
    after = [ "hermes-vault-access.service" "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
    serviceConfig.EnvironmentFile = [ config.sops.templates."hermes.env".path ];
  };
  systemd.services.hermes-backend = {
    requires = [ "hermes-vault-access.service" ];
    after = [ "hermes-vault-access.service" "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
    serviceConfig.EnvironmentFile = [ config.sops.templates."hermes.env".path ];
  };
}
  ;
}
