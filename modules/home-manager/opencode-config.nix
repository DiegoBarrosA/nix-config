# OpenCode configuration module for Home Manager
# Manages OpenCode config including MCP servers (Jira, Obsidian, mcp-nixos)
# Expects programs.mcp-config (from flake homeModules `mcp-config`, or import mcp-config.nix).
# No hardcoded personal info - all paths/secrets via options or env vars
{
  config,
  lib,
  pkgs,
  customPkgs,
  ...
}:
let
  cfg = config.programs.opencode-config;
  mcpCfg = config.programs.mcp-config;
  jsonFormat = pkgs.formats.json { };

  # Names of servers that opencode-config manages explicitly (from programs.mcp-config options).
  # Any programs.mcp.servers entry NOT in this set is auto-included below.
  explicitServerNames = lib.concatLists [
    (lib.optional mcpCfg.obsidian.enable "obsidian")
    (lib.optional mcpCfg.mcpNixos.enable "nixos")
    (lib.optional mcpCfg.mcpTelegram.enable "telegram")
    (lib.optional mcpCfg.jobspy.enable "jobspy")
    (lib.optional mcpCfg.github.enable "github")
    (lib.optional mcpCfg.playwright.enable "playwright")
    (lib.optional mcpCfg.thunderbird.enable "thunderbird")
  ];

  # Convert a programs.mcp.servers entry to opencode MCP format.
  # programs.mcp.servers stores command as a string + optional args list;
  # opencode expects command as a flat list.  The env field uses {env:VAR}
  # syntax in both formats, so it passes through unchanged as `environment`.
  toOpencodeEntry =
    _name: srv:
    let
      cmdList = if builtins.isList srv.command then srv.command else [ srv.command ];
      fullCmd = cmdList ++ (srv.args or [ ]);
    in
    {
      type = "local";
      command = fullCmd;
      enabled = true;
    }
    // lib.optionalAttrs ((srv.env or { }) != { }) {
      environment = srv.env;
    };

  # Servers from programs.mcp.servers not already handled by mcpCfg options.
  # This picks up employer MCP servers (jira, confluence, trello, tempo, …)
  # added by external modules (e.g. employer-mcp-config.nix) without requiring
  # any changes to those modules.
  additionalMcpServers = lib.mapAttrs toOpencodeEntry (
    lib.filterAttrs (name: _: !builtins.elem name explicitServerNames) (
      config.programs.mcp.servers or { }
    )
  );

  # Build MCP servers configuration from shared mcp-config
  mcpServers =
    lib.optionalAttrs mcpCfg.obsidian.enable {
      obsidian = {
        type = "local";
        command = [
          "uvx"
          "mcp-obsidian"
        ];
        enabled = true;
        environment = {
          OBSIDIAN_HOST = mcpCfg.obsidian.host;
          OBSIDIAN_PORT = toString mcpCfg.obsidian.port;
          OBSIDIAN_API_KEY = "{env:OBSIDIAN_API_KEY}";
        };
      };
    }
    // lib.optionalAttrs mcpCfg.mcpNixos.enable {
      nixos = {
        type = "local";
        command = [
          "${pkgs.mcp-nixos}/bin/mcp-nixos"
        ];
        enabled = true;
      };
    }
    // lib.optionalAttrs mcpCfg.mcpTelegram.enable {
      telegram = {
        type = "local";
        command = [
          "uvx"
          "simple-telegram-mcp"
        ];
        enabled = true;
      };
    }
    // lib.optionalAttrs mcpCfg.jobspy.enable {
      jobspy = {
        type = "local";
        command = [ "${mcpCfg.jobspy.package}/bin/jobspy-mcp" ];
        enabled = true;
      };
    }
    // lib.optionalAttrs mcpCfg.github.enable {
      github = {
        type = "local";
        command = [ "${mcpCfg.github.package}/bin/github-mcp-server" ];
        enabled = true;
        environment = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_TOKEN}";
        };
      };
    }
    // lib.optionalAttrs mcpCfg.playwright.enable {
      playwright = {
        type = "local";
        command = [
          "${mcpCfg.playwright.package}/bin/playwright-mcp"
        ]
        ++ lib.optionals (mcpCfg.playwright.browserPath != null) [
          "--executable-path"
          mcpCfg.playwright.browserPath
        ];
        enabled = true;
      };
    }
    // lib.optionalAttrs mcpCfg.thunderbird.enable {
      thunderbird = {
        type = "local";
        command = [ "${mcpCfg.thunderbird.package}/bin/thunderbird-mcp" ];
        enabled = true;
      };
    }
    // additionalMcpServers
    // cfg.extraMcpServers;

  # Build provider configuration combining Go, Zen, and custom providers
  providerConfig =
    lib.optionalAttrs cfg.opencodeGo.enable {
      "opencode-go" = {
        npm = "@ai-sdk/openai-compatible";
        name = "OpenCode Go";
        options = {
          baseURL = "https://opencode.ai/zen/go/v1";
          apiKey = "{env:${cfg.opencodeGo.apiKeyEnvVar}}";
        };
        models = {
          "deepseek-v4-pro" = {
            name = "DeepSeek V4 Pro";
          };
          "deepseek-v4-flash" = {
            name = "DeepSeek V4 Flash";
          };
          "glm-5.1" = {
            name = "GLM 5.1";
          };
          "glm-5" = {
            name = "GLM 5";
          };
          "kimi-k2.6" = {
            name = "Kimi K2.6";
          };
          "kimi-k2.5" = {
            name = "Kimi K2.5";
          };
          "mimo-v2.5-pro" = {
            name = "MiMo V2.5 Pro";
          };
          "mimo-v2.5" = {
            name = "MiMo V2.5";
          };
          "minimax-m2.7" = {
            name = "MiniMax M2.7";
          };
          "minimax-m2.5" = {
            name = "MiniMax M2.5";
          };
          "qwen3.6-plus" = {
            name = "Qwen 3.6 Plus";
          };
          "qwen3.5-plus" = {
            name = "Qwen 3.5 Plus";
          };
        };
      };
    }
    // lib.optionalAttrs cfg.opencodeZen.enable {
      "opencode" = {
        npm = "@ai-sdk/openai-compatible";
        name = "OpenCode Zen";
        options = {
          baseURL = "https://opencode.ai/zen/v1";
          apiKey = "{env:${cfg.opencodeZen.apiKeyEnvVar}}";
        };
        models = {
          "deepseek-v4-flash-free" = {
            name = "DeepSeek V4 Flash Free";
          };
          "minimax-m2.5-free" = {
            name = "MiniMax M2.5 Free";
          };
          "ring-2.6-1t-free" = {
            name = "Ring 2.6 1T Free";
          };
          "nemotron-3-super-free" = {
            name = "Nemotron 3 Super Free";
          };
          "big-pickle" = {
            name = "Big Pickle";
          };
          "gpt-5-nano" = {
            name = "GPT 5 Nano";
          };
          "claude-haiku-4-5" = {
            name = "Claude Haiku 4.5";
          };
          "qwen3.5-plus" = {
            name = "Qwen 3.5 Plus (Zen)";
          };
          "claude-sonnet-4-5" = {
            name = "Claude Sonnet 4.5";
          };
          "claude-opus-4-5" = {
            name = "Claude Opus 4.5";
          };
          "gpt-5.4" = {
            name = "GPT 5.4";
          };
        };
      };
    }
    // (if cfg.provider.enable then cfg.provider.config else { });

  # Determine the default model
  defaultModel =
    if cfg.opencodeGo.enable then "opencode-go/deepseek-v4-flash" else cfg.provider.defaultModel;

  # Build the full opencode.json config.
  # Use recursiveUpdate so cfg.extraConfig.provider merges with (instead of
  # replacing) the providers built from opencodeGo/opencodeZen options.
  baseConfig = {
    "$schema" = "https://opencode.ai/config.json";
  }
  // lib.optionalAttrs (mcpServers != { }) { mcp = mcpServers; }
  // lib.optionalAttrs (providerConfig != { } || defaultModel != null) {
    provider = providerConfig;
    model = defaultModel;
  };

  # Merge baseConfig with extraConfig, ensuring plugin lists are concatenated
  opencodeConfig =
    let
      merged = lib.recursiveUpdate baseConfig cfg.extraConfig;
      # Concatenate plugin lists if both exist (don't replace, merge)
      finalPlugins = (baseConfig.plugin or [ ]) ++ (cfg.extraConfig.plugin or [ ]);
    in
    lib.filterAttrs (k: v: v != null && v != { }) (
      merged // lib.optionalAttrs (finalPlugins != [ ]) { plugin = finalPlugins; }
    );
in
{
  options.programs.opencode-config = {
    enable = lib.mkEnableOption "OpenCode configuration management";

    # OpenCode Go subscription configuration
    opencodeGo = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable OpenCode Go provider configuration.
          OpenCode Go is a $10/month subscription for reliable access to popular open coding models.
        '';
      };

      apiKeyEnvVar = lib.mkOption {
        type = lib.types.str;
        default = "OPENCODE_API_KEY";
        description = ''
          Environment variable containing the OpenCode API key.
          OpenCode uses a single API key for both Go and Zen providers
          (same subscription, same auth backend).
        '';
      };
    };

    # OpenCode Zen pay-per-use configuration
    opencodeZen = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable OpenCode Zen provider configuration.
          OpenCode Zen is a pay-per-use gateway with curated, tested models.
        '';
      };

      apiKeyEnvVar = lib.mkOption {
        type = lib.types.str;
        default = "OPENCODE_API_KEY";
        description = ''
          Environment variable containing the OpenCode API key.
          OpenCode uses a single API key for both Go and Zen providers
          (same subscription, same auth backend).
        '';
      };
    };

    # Provider configuration (optional, for manual override)
    provider = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable provider configuration in opencode.json.
          When disabled, provider config is not managed by Nix (edit manually).
        '';
      };

      config = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          Provider configuration. Keys are provider names, values are provider config.
        '';
        example = lib.literalExpression ''
          {
            anthropic = {
              npm = "@ai-sdk/anthropic";
              name = "Anthropic";
              models = {
                "claude-sonnet-4" = {
                  name = "Claude Sonnet 4";
                };
              };
            };
          }
        '';
      };

      defaultModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default model to use.";
      };
    };

    # Extra MCP servers (user-defined, merged with shared MCP config)
    extraMcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Additional MCP servers to configure.";
    };

    # Extra config (merged into opencode.json)
    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra configuration to merge into opencode.json.";
    };

    # Telegram channel configuration (for OpenClaw)
    channels.telegram = {
      enable = lib.mkEnableOption "Telegram notification channel for OpenCode";

      botTokenEnvVar = lib.mkOption {
        type = lib.types.str;
        default = "TELEGRAM_BOT_TOKEN";
        description = "Environment variable containing the Telegram bot token.";
      };

      userIdEnvVar = lib.mkOption {
        type = lib.types.str;
        default = "TELEGRAM_USER_ID";
        description = "Environment variable containing the Telegram user ID.";
      };

      dmPolicy = lib.mkOption {
        type = lib.types.enum [
          "allowlist"
          "open"
          "disabled"
        ];
        default = "allowlist";
        description = "Policy for direct messages.";
      };

      groupPolicy = lib.mkOption {
        type = lib.types.enum [
          "open"
          "disabled"
          "allowlist"
        ];
        default = "disabled";
        description = "Policy for group chat messages.";
      };
    };

    # Telegram notification scripts (for opencode CLI)
    notifications.telegram = {
      enable = lib.mkEnableOption "send-telegram-message helper script for Telegram notifications";

      enableShellHook = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install opencode-with-notifications wrapper script.";
      };
    };

    secretEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Files whose contents should be exported into the environment before running opencode.";
    };

    # Named profiles — each generates an opencode-{name} wrapper script with its own config dir
    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            scriptName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Override the generated script name. Defaults to opencode-{profile-name}.";
            };
            config = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
              description = "opencode.json content for this profile. MCP servers and plugins are inherited from the shared config.";
            };
          };
        }
      );
      default = { };
      description = ''
        Named opencode profiles. Each profile gets its own config dir under
        ~/.config/opencode-profiles/<name>/ (separate sessions/history) and a
        wrapper script opencode-<name> that launches opencode with that profile.
        MCP servers are shared from the main config.
      '';
      example = lib.literalExpression ''
        {
          work = {
            config = {
              model = "nvidia-inference/aws/anthropic/claude-opus-4-5";
              provider."nvidia-inference" = { ... };
            };
          };
          personal = {
            config = {
              model = "opencode/big-pickle";
              provider.groq = { ... };
            };
          };
        }
      '';
    };

    # Skills configuration
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        OpenCode skills to install. Keys are skill names (directory names),
        values are the content of the SKILL.md file.

        Skills are installed to ~/.config/opencode/skills/<name>/SKILL.md
      '';
      example = lib.literalExpression ''
        {
          "my-skill" = '''
            ---
            name: my-skill
            description: A custom skill
            ---
            # My Skill
            Instructions here...
          ''';
        }
      '';
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        OpenCode agents to install. Keys are agent filenames (without .md),
        values are the markdown content.
        Deployed to ~/.config/opencode/agents/<name>.md
      '';
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        OpenCode commands to install. Keys are command filenames (without .md),
        values are the markdown content.
        Deployed to ~/.config/opencode/commands/<name>.md
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      secretEnvNames = lib.attrNames cfg.secretEnv;
      secretEnvScript = lib.concatMapStringsSep "\n" (name: ''
        if [ -r "${cfg.secretEnv.${name}}" ]; then
          export ${name}="$( ${pkgs.coreutils}/bin/cat "${cfg.secretEnv.${name}}" )"
        fi
      '') secretEnvNames;
      opencodeWrapper = pkgs.writeShellScriptBin "opencode" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        ${secretEnvScript}
        exec ${pkgs.opencode}/bin/opencode "$@"
      '';
      opencodePackage =
        if secretEnvNames == [ ] then
          pkgs.opencode
        else
          pkgs.symlinkJoin {
            name = "opencode-with-secrets";
            paths = [
              opencodeWrapper
              pkgs.opencode
            ];
          };

      # Build the shared base (MCP) used by all profiles
      sharedBase =
        lib.optionalAttrs (mcpServers != { }) { mcp = mcpServers; };

      # Generate a wrapper script for each profile (name defaults to opencode-{profileName})
      profileScripts = lib.mapAttrsToList (
        profileName: profileCfg:
        let
          scriptName =
            if profileCfg.scriptName != null then profileCfg.scriptName else "opencode-${profileName}";
        in
        pkgs.writeShellScriptBin scriptName ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          ${secretEnvScript}
          # Share node_modules from the main config dir to avoid re-installing packages
          PROFILE_DIR="$HOME/.config/opencode-profiles/${profileName}/opencode"
          mkdir -p "$PROFILE_DIR"
          if [ ! -e "$PROFILE_DIR/node_modules" ] && [ -d "$HOME/.config/opencode/node_modules" ]; then
            ln -sf "$HOME/.config/opencode/node_modules" "$PROFILE_DIR/node_modules"
          fi
          exec env XDG_CONFIG_HOME="$HOME/.config/opencode-profiles/${profileName}" \
            ${pkgs.opencode}/bin/opencode "$@"
        ''
      ) cfg.profiles;

      # Generate xdg.configFile entries for each profile (opencode.json)
      profileConfigFiles = lib.foldlAttrs (
        acc: profileName: profileCfg:
        let
          profileJson = lib.filterAttrs (k: v: v != null && v != { }) (
            lib.recursiveUpdate sharedBase profileCfg.config
          );
        in
        acc
        // {
          "opencode-profiles/${profileName}/opencode/opencode.json" = {
            source = jsonFormat.generate "opencode-${profileName}.json" profileJson;
            force = true;
          };
        }
        // lib.mapAttrs' (
          skillName: content:
          lib.nameValuePair "opencode-profiles/${profileName}/opencode/skills/${skillName}/SKILL.md" {
            text = content;
          }
        ) cfg.skills
      ) { } cfg.profiles;
    in
    lib.mkMerge [
      {
        home.packages = [
          opencodePackage
        ]
        ++ lib.optional mcpCfg.mcpNixos.enable pkgs.mcp-nixos
        ++ profileScripts;

        xdg.configFile = {
          "opencode/opencode.json" = {
            source = jsonFormat.generate "opencode.json" opencodeConfig;
            force = true;
          };
        }
        // lib.mapAttrs' (
          name: content:
          lib.nameValuePair "opencode/skills/${name}/SKILL.md" {
            text = content;
          }
        ) cfg.skills
        // lib.mapAttrs' (
          name: content:
          lib.nameValuePair "opencode/agents/${name}.md" {
            text = content;
          }
        ) cfg.agents
        // lib.mapAttrs' (
          name: content:
          lib.nameValuePair "opencode/commands/${name}.md" {
            text = content;
          }
        ) cfg.commands
        // profileConfigFiles;
      }

      (lib.mkIf cfg.notifications.telegram.enable {
        home.packages = [
          (pkgs.writeShellScriptBin "send-telegram-message" ''
            TOKEN=$(cat /run/secrets/telegram-bot-token 2>/dev/null)
            CHAT_ID=$(cat /run/secrets/telegram-user-id 2>/dev/null)
            if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
              echo "Error: Telegram secrets not found at /run/secrets/" >&2
              exit 1
            fi
            if [ $# -gt 0 ]; then
              MESSAGE="$*"
            else
              MESSAGE=$(cat)
            fi
            curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
              -d "chat_id=$CHAT_ID" \
              -d "text=$MESSAGE" \
              -d "parse_mode=markdown" > /dev/null
          '')
        ]
        ++ lib.optionals cfg.notifications.telegram.enableShellHook [
          (pkgs.writeShellScriptBin "opencode-with-notifications" ''
            opencode "$@"
            EXIT_CODE=$?
            if [ $EXIT_CODE -eq 0 ]; then
              send-telegram-message "opencode: Task completed successfully"
            else
              send-telegram-message "opencode: Task failed (exit $EXIT_CODE)"
            fi
            exit $EXIT_CODE
          '')
        ];
      })
    ]
  );
}
