{
  config,
  lib,
  pkgs,
  inputs,
  customPkgs,
  privateConfig ? { },
  ...
}:
let
  cfg = config.programs.zed-editor-custom;

  # opencode-config exposes a builder for per-profile ACP wrappers and the
  # sops secret-loader. Guard on the module being enabled + the helper present.
  ocCfg = config.programs.opencode-config or { };
  ocEnabled = (ocCfg.enable or false) && (ocCfg ? _mkAcpWrapper);
  ocProfiles = lib.attrNames (ocCfg.profiles or { });
  mkAcp = ocCfg._mkAcpWrapper or (_: null);

  # ACP agent_servers entries for each opencode profile (work/personal/...).
  # Each launches `opencode acp` with that profile's XDG_CONFIG_HOME + secrets.
  opencodeAcpAgents = lib.optionalAttrs ocEnabled (
    lib.listToAttrs (
      map (profileName: {
        name = "OpenCode ${lib.toUpper (builtins.substring 0 1 profileName)}${builtins.substring 1 (builtins.stringLength profileName) profileName}";
        value = {
          command = "${mkAcp profileName}/bin/opencode-acp-${profileName}";
          args = [ ];
        };
      }) ocProfiles
    )
  );

  # Official zed-industries ACP adapters (stable, packaged in nixpkgs).
  # NB: name it "Claude Agent (ACP)" — NOT "Claude Code" — because Zed ships a
  # built-in registry agent literally named "Claude Code". A same-name entry
  # deep-merges with Zed's runtime-written registry entry (mixing `type:registry`
  # with our `command`), producing an invalid hybrid. A distinct name avoids the
  # collision entirely.
  claudeCodeAgent = {
    "Claude Agent (ACP)" = {
      command = "${pkgs.claude-agent-acp}/bin/claude-agent-acp";
      args = [ ];
    };
  };
  codexAgent = {
    "Codex" = {
      # customPkgs.codex-acp = our 0.16.0 build (codex-core rust-v0.137.0),
      # not nixpkgs' stale 0.13.0 (rust-v0.128.0) whose old core failed with
      # 401 "workspace not authorized in this region" + unknown-model metadata.
      command = "${customPkgs.codex-acp}/bin/codex-acp";
      # Pin the model your ChatGPT workspace is authorized for (the plain
      # `codex` TUI defaults to gpt-5.6-sol for this account).
      args = [
        "-c"
        "model=gpt-5.6-sol"
      ];
    };
  };

  agentServers = opencodeAcpAgents // claudeCodeAgent // codexAgent;

  # Build language model providers from privateConfig and standard providers
  # Handle both full privateConfig and opencodeConfig-only variants
  workOpencodeCfg = privateConfig.opencodeConfig or privateConfig;

  # Work provider key: exported by private-config (workProviderId); when only
  # the opencode config subset is passed through, derive it from the default
  # model's "<provider>/<model>" prefix.
  workProviderId =
    privateConfig.workProviderId or (
      let
        m = workOpencodeCfg.model or null;
      in
      if m == null then null else lib.head (lib.splitString "/" m)
    );

  workModels =
    if workProviderId == null then { } else workOpencodeCfg.provider.${workProviderId}.models or { };

  workBaseUrl =
    if workProviderId == null then
      null
    else
      workOpencodeCfg.provider.${workProviderId}.options.baseURL or null;

  languageModels = {
    # DeepSeek built-in provider
    deepseek = {
      api_url = "https://api.deepseek.com/v1";
    };

    # Work inference API via openai_compatible (only present when private-config supplies the URL)
    openai_compatible = lib.optionalAttrs (workBaseUrl != null && workModels != { }) {
      ${privateConfig.workProviderLabel or "Work"} = {
        api_url = workBaseUrl;
        available_models = lib.mapAttrsToList (modelId: modelCfg: {
          name = modelId;
          display_name = modelCfg.name or modelId;
          max_tokens = modelCfg.options.max_tokens or 8192;
        }) workModels;
      };
    } // {
      "OpenCode Go" = {
        api_url = "https://opencode.ai/zen/go/v1";
        available_models = [
          { name = "deepseek-v4-flash"; display_name = "DeepSeek V4 Flash (Go)"; max_tokens = 8192; }
          { name = "qwen3.5-plus"; display_name = "Qwen 3.5 Plus (Go)"; max_tokens = 8192; }
          { name = "minimax-m2.5"; display_name = "MiniMax M2.5 (Go)"; max_tokens = 8192; }
          { name = "deepseek-v4-pro"; display_name = "DeepSeek V4 Pro (Go)"; max_tokens = 8192; }
          { name = "glm-5.1"; display_name = "GLM 5.1 (Go)"; max_tokens = 8192; }
          { name = "kimi-k2.6"; display_name = "Kimi K2.6 (Go)"; max_tokens = 8192; }
          { name = "mimo-v2.5-pro"; display_name = "MiMo V2.5 Pro (Go)"; max_tokens = 8192; }
          { name = "qwen3.6-plus"; display_name = "Qwen 3.6 Plus (Go)"; max_tokens = 8192; }
        ];
      };

      "OpenCode Zen" = {
        api_url = "https://opencode.ai/zen/v1";
        available_models = [
          { name = "deepseek-v4-flash-free"; display_name = "DeepSeek V4 Flash Free (Zen)"; max_tokens = 8192; }
          { name = "minimax-m2.5-free"; display_name = "MiniMax M2.5 Free (Zen)"; max_tokens = 8192; }
          { name = "gpt-5-nano"; display_name = "GPT 5 Nano (Zen)"; max_tokens = 8192; }
          { name = "claude-haiku-4-5"; display_name = "Claude Haiku 4.5 (Zen)"; max_tokens = 8192; }
          { name = "claude-sonnet-4-5"; display_name = "Claude Sonnet 4.5 (Zen)"; max_tokens = 8192; }
          { name = "claude-opus-4-5"; display_name = "Claude Opus 4.5 (Zen)"; max_tokens = 8192; }
        ];
      };
    };
  };

  # Base user settings. Theme is managed by Stylix's Zed target
  # (themes.stylix via tinted-zed + userSettings.theme = "Base16 <scheme>").
  # Fonts/sizes and icon theme are set explicitly here because Stylix's
  # applications size (11) * 4/3 renders the UI a bit small, and Zed has no
  # icon theme by default (null -> generic/small icons).
  baseSettings = {
    "buffer_font_size" = lib.mkForce 15;
    "ui_font_size" = lib.mkForce 16;
    "agent_font_size" = 15;
    # File-type icons in the project panel/tabs (fixes tiny/generic icons).
    "icon_theme" = "Material Icon Theme";
    "tab_size" = 2;
    "hard_tabs" = false;
    "scrollbar" = {
      show = "auto";
    };
    "relative_line_numbers" = false;
    "indent_guides" = {
      enabled = true;
      coloring = "fixed";
      line_width = 1;
    };
    "telemetry" = {
      diagnostics = false;
      metrics = false;
    };
    "format_on_save" = "on";
    "remove_trailing_whitespace_on_save" = true;
    "ensure_final_newline_on_save" = true;
    "autosave" = "off";
    "show_inline_completions" = true;
    "agent" = {
      "default_profile" = "agent";
      "always_allow_tool_actions" = false;
    };
    "agent_servers" = agentServers;
    "language_models" = languageModels;
  };

  # Keymap settings - vim mode since user uses vim everywhere
  keymaps = {
    vim_mode = true;
  };
in
{
  options.programs.zed-editor-custom = {
    enable = lib.mkEnableOption "Zed editor with MCP and LLM provider configuration";

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to integrate MCP servers from programs.mcp.servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      defaultEditor = false;
      enableMcpIntegration = cfg.enableMcpIntegration;
      # HM fully owns settings.json (Zed can't persist runtime edits over it).
      # This prevents Zed from clobbering agent_servers/theme on next launch.
      mutableUserSettings = false;
      # Keymap is fully HM-owned too, so Zed can't clobber/duplicate bindings.
      mutableUserKeymaps = false;

      # Fix Stylix's tinted-zed theme: your base16 scheme's `type` is
      # "material-darker" (not "dark"/"light"), so the generated theme's
      # `appearance` renders as "unspecified" — which Zed rejects, silently
      # falling back to the default theme. Post-process Stylix's generated
      # theme JSON to force every variant's appearance to "dark".
      themes.stylix = lib.mkIf (config.stylix.enable or false) (lib.mkForce (
        let
          upstream = config.lib.stylix.colors {
            templateRepo = inputs.stylix.inputs.tinted-zed;
            target = "base16";
          };
        in
        pkgs.runCommand "zed-stylix-theme-fixed.json" { } ''
          ${pkgs.jq}/bin/jq '.themes |= map(.appearance = "dark")' \
            ${upstream} > "$out"
        ''
      ));

      extensions = [
        "base16"
        "material-icon-theme"
        "nix"
        "rust"
        "typescript"
        "toml"
        "git-firefly"
        "tailwind"
        "docker-compose"
        "sql"
        "markdown"
        "proto"
        "elixir"
        "go"
        "python"
        "bash"
      ];

      userSettings = baseSettings
        // lib.optionalAttrs (config.fontProfiles.enable && config.fontProfiles.monospace.family != null) {
          # mkForce: Stylix's Zed target also sets these; ours must win.
          "buffer_font_family" = lib.mkForce config.fontProfiles.monospace.family;
          "ui_font_family" = lib.mkForce (lib.removeSuffix "*" config.fontProfiles.regular.family);
        }
        // {
          vim_mode = true;
        };

      userKeymaps = [
        {
          context = "Editor && vim_mode == normal && !VimWaiting && !menu";
          bindings = {
            "space space" = "file_finder::Toggle";
            "space f f" = "file_finder::Toggle";
            "space f g" = "pane::DeploySearch";
            "space g g" = "git_panel::ToggleFocus";
            "space b d" = "pane::CloseActiveItem";
            "space w s" = "workspace::Save";
            "space w q" = "workspace::CloseWindow";
            "space t t" = "terminal_panel::ToggleFocus";
            "space c a" = "agent::ToggleFocus";
          };
        }
        {
          context = "Editor && vim_mode == insert";
          bindings = {
            "ctrl-j" = "editor::ShowSignatureHelp";
          };
        }
      ];

      # Must be a list: home-manager merges tasks.json with jq as arrays ($dynamic + $static).
      userTasks = [
        {
          label = "nix build";
          command = "nix";
          args = [ "build" ".#\${ZED_CUSTOM_RUST_PACKAGE}" ];
          cwd = "\${ZED_WORKTREE_ROOT}";
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "never";
          shell = "system";
        }
        {
          label = "nix flake update";
          command = "nix";
          args = [ "flake" "update" ];
          cwd = "\${ZED_WORKTREE_ROOT}";
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "never";
          shell = "system";
        }
        {
          label = "nix fmt";
          command = "nix";
          args = [ "fmt" ];
          cwd = "\${ZED_WORKTREE_ROOT}";
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "on_success";
          shell = "system";
        }
      ];
    };
  };
}
