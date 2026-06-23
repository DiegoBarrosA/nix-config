# Obsidian configuration module for Home Manager
# Manages Obsidian app, vault settings, plugins, and Syncthing integration
# Uses 'programs.obsidian-vault' to avoid conflict with built-in home-manager module
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.obsidian-vault;
  jsonFormat = pkgs.formats.json { };

  # Default core plugins configuration
  defaultCorePlugins = {
    file-explorer = true;
    global-search = true;
    switcher = true;
    graph = true;
    backlink = true;
    canvas = true;
    outgoing-link = true;
    tag-pane = true;
    footnotes = false;
    properties = true;
    page-preview = true;
    daily-notes = true;
    templates = true;
    note-composer = true;
    command-palette = true;
    slash-command = false;
    editor-status = true;
    bookmarks = true;
    markdown-importer = false;
    zk-prefixer = false;
    random-note = false;
    outline = true;
    word-count = true;
    slides = true;
    audio-recorder = false;
    workspaces = false;
    file-recovery = true;
    publish = false;
    sync = false;
    bases = true;
    webviewer = false;
  };
in
{
  options.programs.obsidian-vault = {
    enable = lib.mkEnableOption "Obsidian note-taking application with vault configuration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.obsidian;
      defaultText = lib.literalExpression "pkgs.obsidian";
      description = "The Obsidian package to install.";
    };

    vaultPath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the Obsidian vault directory.";
      example = "/home/user/Notes";
    };

    # App settings (app.json)
    settings = {
      vimMode = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Vim keybindings.";
      };

      showLineNumber = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show line numbers in editor.";
      };

      showInlineTitle = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Show inline title in notes.";
      };

      alwaysUpdateLinks = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Automatically update internal links when files are renamed.";
      };

      newFileLocation = lib.mkOption {
        type = lib.types.enum [
          "root"
          "current"
          "folder"
        ];
        default = "folder";
        description = "Where to create new notes.";
      };

      newFileFolderPath = lib.mkOption {
        type = lib.types.str;
        default = "Quick notes";
        description = "Folder path for new notes when newFileLocation is 'folder'.";
      };

      attachmentFolderPath = lib.mkOption {
        type = lib.types.str;
        default = "Attachments";
        description = "Folder path for attachments.";
      };

      openBehavior = lib.mkOption {
        type = lib.types.enum [
          "new-tab"
          "daily"
          "last"
        ];
        default = "daily";
        description = "Behavior when opening Obsidian.";
      };

      pdfExportSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {
          pageSize = "Letter";
          landscape = false;
          margin = "0";
          downscalePercent = 100;
        };
        description = "PDF export settings.";
      };
    };

    # Appearance settings (appearance.json)
    appearance = {
      theme = lib.mkOption {
        type = lib.types.enum [
          "moonstone"
          "obsidian"
        ];
        default = "moonstone";
        description = "Base theme (moonstone = light adaptable, obsidian = dark).";
      };

      stylixTheme = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable stylix-based theme using base16 colors.";
      };

      cssTheme = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Community theme name.";
      };

      accentColor = lib.mkOption {
        type = lib.types.str;
        default = "#82AAFF";
        description = "Accent color in hex format.";
      };

      baseFontSize = lib.mkOption {
        type = lib.types.int;
        default = 26;
        description = "Base font size in pixels.";
      };

      textFontFamily = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Text font family (empty for default).";
      };

      showViewHeader = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show view header.";
      };

      showRibbon = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show left ribbon.";
      };

      nativeMenus = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use native OS menus.";
      };
    };

    # Core plugins configuration
    corePlugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = defaultCorePlugins;
      description = "Core plugins enable/disable configuration.";
    };

    # Community plugins
    communityPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "obsidian-excalidraw-plugin"
        "dataview"
        "templater-obsidian"
      ];
      description = "List of community plugin IDs to enable.";
    };

    # Daily notes plugin configuration
    dailyNotes = {
      folder = lib.mkOption {
        type = lib.types.str;
        default = "Daily";
        description = "Folder for daily notes.";
      };

      format = lib.mkOption {
        type = lib.types.str;
        default = "YYYY/MM-MMMM/YYYY-MM-DD";
        description = "Date format for daily note filenames.";
      };

      template = lib.mkOption {
        type = lib.types.str;
        default = "Templates/Daily";
        description = "Template to use for daily notes.";
      };
    };

    # Templates plugin configuration
    templates = {
      folder = lib.mkOption {
        type = lib.types.str;
        default = "Templates";
        description = "Folder containing templates.";
      };
    };

    # REST API plugin for MCP integration
    restApi = {
      enable = lib.mkEnableOption "Obsidian Local REST API plugin for MCP integration";

      apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing the Obsidian REST API key.
          The file should contain only the API key.
        '';
      };

      apiKeyEnvVar = lib.mkOption {
        type = lib.types.str;
        default = "OBSIDIAN_API_KEY";
        description = "Environment variable name for the API key.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for the REST API.";
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 27124;
        description = "Port for the REST API.";
      };

      enableInsecure = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the plugin's non-encrypted HTTP server (unencrypted tunnel).";
      };

      insecurePort = lib.mkOption {
        type = lib.types.int;
        default = 27123;
        description = "Port for the non-encrypted HTTP server.";
      };
    };

    # Syncthing integration
    syncthing = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Automatically add vault to Syncthing sync (when Obsidian is enabled).";
      };

      folderId = lib.mkOption {
        type = lib.types.str;
        default = "obsidian-vault";
        description = "Syncthing folder ID for the vault.";
      };

      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of Syncthing device names to sync with.";
      };
    };

    # Self-hosted LiveSync (obsidian-livesync plugin) integration
    livesync = {
      enable = lib.mkEnableOption "Self-hosted LiveSync plugin for Obsidian sync";

      couchDB_URI = lib.mkOption {
        type = lib.types.str;
        default = "https://sync.minerales.network";
        description = "CouchDB server URI.";
      };

      couchDB_DBNAME = lib.mkOption {
        type = lib.types.str;
        default = "obsidiannotes";
        description = "CouchDB database name.";
      };

      couchDB_USER = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "CouchDB username for livesync.";
      };

      couchDB_PASSWORD_FILE = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing CouchDB password for livesync.
          The file should contain only the password.
        '';
      };

      passphraseFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing the E2EE passphrase for livesync.
          The file should contain only the passphrase.
        '';
      };

      syncOnStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Start syncing automatically when Obsidian starts.";
      };

      periodicReplication = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable periodic replication.";
      };

      syncOnFileOpen = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Sync when file is opened.";
      };

      encrypt = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable end-to-end encryption.";
      };

      usePathObfuscation = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Obfuscate file paths in the database.";
      };

      batchSave = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable batch save for better performance.";
      };

      useHistory = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable change history.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Obsidian package
    home.packages = [ cfg.package ];

    # Ensure vault and plugin directories exist
    home.activation.createObsidianVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${cfg.vaultPath}"
      $DRY_RUN_CMD mkdir -p "${cfg.vaultPath}/.obsidian"
      $DRY_RUN_CMD mkdir -p "${cfg.vaultPath}/${cfg.settings.attachmentFolderPath}"
      $DRY_RUN_CMD mkdir -p "${cfg.vaultPath}/${cfg.settings.newFileFolderPath}"
      $DRY_RUN_CMD mkdir -p "${cfg.vaultPath}/.obsidian/plugins/obsidian-livesync"
      $DRY_RUN_CMD mkdir -p "${cfg.vaultPath}/.obsidian/snippets"
    '';

    # Generate app.json
    home.file."${cfg.vaultPath}/.obsidian/app.json" = {
      force = true;
      source = jsonFormat.generate "obsidian-app.json" {
        vimMode = cfg.settings.vimMode;
        showLineNumber = cfg.settings.showLineNumber;
        showInlineTitle = cfg.settings.showInlineTitle;
        alwaysUpdateLinks = cfg.settings.alwaysUpdateLinks;
        newFileLocation = cfg.settings.newFileLocation;
        newFileFolderPath = cfg.settings.newFileFolderPath;
        attachmentFolderPath = cfg.settings.attachmentFolderPath;
        openBehavior = cfg.settings.openBehavior;
        pdfExportSettings = cfg.settings.pdfExportSettings;
      };
    };

    # Generate appearance.json
    home.file."${cfg.vaultPath}/.obsidian/appearance.json" = {
      force = true;
      source = jsonFormat.generate "obsidian-appearance.json" (
        {
          theme = cfg.appearance.theme;
          accentColor = cfg.appearance.accentColor;
          baseFontSize = cfg.appearance.baseFontSize;
          showViewHeader = cfg.appearance.showViewHeader;
          showRibbon = cfg.appearance.showRibbon;
          nativeMenus = cfg.appearance.nativeMenus;
          baseFontSizeAction = true;
        }
        // lib.optionalAttrs (cfg.appearance.cssTheme != "") { cssTheme = cfg.appearance.cssTheme; }
        // lib.optionalAttrs (cfg.appearance.textFontFamily != "") {
          textFontFamily = cfg.appearance.textFontFamily;
        }
      );
    };

    # Generate stylix theme CSS snippet
    home.file."${cfg.vaultPath}/.obsidian/snippets/stylix-theme.css" = {
      force = true;
      text =
        let
          inherit (config.colorscheme) colors;
          # Convert hex colors to be used in CSS variables
          hexToCssVar = hex: hex;
          # Some CSS properties need the hex without # for filters, etc.
          hexWithoutHash = hex: builtins.substring 1 (builtins.stringLength hex - 1) hex;
        in
        ''
          /* Stylix theme based on base16 colorscheme */
          :root {
            --stylix-base00: ${colors.base00};
            --stylix-base01: ${colors.base01};
            --stylix-base02: ${colors.base02};
            --stylix-base03: ${colors.base03};
            --stylix-base04: ${colors.base04};
            --stylix-base05: ${colors.base05};
            --stylix-base06: ${colors.base06};
            --stylix-base07: ${colors.base07};
            --stylix-base08: ${colors.base08};
            --stylix-base09: ${colors.base09};
            --stylix-base0A: ${colors.base0A};
            --stylix-base0B: ${colors.base0B};
            --stylix-base0C: ${colors.base0C};
            --stylix-base0D: ${colors.base0D};
            --stylix-base0E: ${colors.base0E};
            --stylix-base0F: ${colors.base0F};
          }

          /* Apply stylix colors to Obsidian UI elements */
          .workspace-tab-header-container {
            background-color: var(--stylix-base00) !important;
          }

          .workspace-tab-header-container .workspace-tab-header.mod-active {
            background-color: var(--stylix-base0D) !important;
            color: var(--stylix-base00) !important;
          }

          .workspace-tab-header-container .workspace-tab-header {
            color: var(--stylix-base04) !important;
          }

          .workspace-tab-header-container .workspace-tab-header:hover:not(.mod-active) {
            background-color: var(--stylix-base02) !important;
          }

          .sidebar-tabs {
            background-color: var(--stylix-base00) !important;
          }

          .sidebar-tabs .sidebar-tab-item {
            color: var(--stylix-base04) !important;
          }

          .sidebar-tabs .sidebar-tab-item.mod-active {
            color: var(--stylix-base0D) !important;
          }

          .sidebar-tabs .sidebar-tab-item:hover:not(.mod-active) {
            background-color: var(--stylix-base02) !important;
          }

          .view-header {
            background-color: var(--stylix-base00) !important;
            border-bottom: 1px solid var(--stylix-base02) !important;
          }

          .view-header .view-header-title {
            color: var(--stylix-base05) !important;
          }

          .view-header .view-header-btn.mod-right {
            color: var(--stylix-base04) !important;
          }

          .view-header .view-header-btn.mod-right:hover {
            background-color: var(--stylix-base02) !important;
          }

          .menu-item {
            color: var(--stylix-base05) !important;
          }

          .menu-item:hover {
            background-color: var(--stylix-base02) !important;
          }

          .menu-item.mod-checked {
            background-color: var(--stylix-base0D) !important;
            color: var(--stylix-base00) !important;
          }

          .status-bar {
            background-color: var(--stylix-base00) !important;
            border-top: 1px solid var(--stylix-base02) !important;
          }

          .status-bar-item {
            color: var(--stylix-base04) !important;
          }

          .status-bar-item.mod-left {
            color: var(--stylix-base0D) !important;
          }

          .cm-line {
            color: var(--stylix-base05) !important;
          }

          .cm-gutter {
            background-color: var(--stylix-base00) !important;
            border-right: 1px solid var(--stylix-base02) !important;
            color: var(--stylix-base04) !important;
          }

          .cm-active-line {
            background-color: var(--stylix-base01) !important;
          }

          .cm-active-line-bg {
            background-color: var(--stylix-base01) !important;
          }

          .cm-searching {
            background-color: var(--stylix-base0D) !important;
          }

          .HyperMD-blockquote {
            border-left-color: var(--stylix-base0D) !important;
          }

          .HyperMD-codeblock {
            background-color: var(--stylix-base01) !important;
            border-color: var(--stylix-base02) !important;
          }

          .markdown-preview-view {
            color: var(--stylix-base05) !important;
            background-color: var(--stylix-base00) !important;
          }

          .markdown-preview-view code {
            background-color: var(--stylix-base01) !important;
            color: var(--stylix-base05) !important;
          }

          .markdown-preview-view h1,
          .markdown-preview-view h2,
          .markdown-preview-view h3,
          .markdown-preview-view h4,
          .markdown-preview-view h5,
          .markdown-preview-view h6 {
            color: var(--stylix-base08) !important;
            border-color: var(--stylix-base02) !important;
          }

          .markdown-preview-view hr {
            border-top-color: var(--stylix-base02) !important;
          }

          .markdown-preview-view blockquote {
            border-left-color: var(--stylix-base0D) !important;
          }

          .markdown-preview-view table,
          .markdown-preview-view th,
          .markdown-preview-view td {
            border-color: var(--stylix-base02) !important;
          }

          .markdown-source-view.mod-cm6 .cm-line {
            color: var(--stylix-base05) !important;
          }

          .markdown-source-view.mod-cm6 .cm-gutter {
            background-color: var(--stylix-base00) !important;
            border-right: 1px solid var(--stylix-base02) !important;
            color: var(--stylix-base04) !important;
          }

          .tag {
            background-color: var(--stylix-base02) !important;
            color: var(--stylix-base05) !important;
          }

          .tag:hover {
            background-color: var(--stylix-base04) !important;
          }

          .cm-variable {
            color: var(--stylix-base0D) !important;
          }

          .cm-function {
            color: var(--stylix-base0D) !important;
          }

          .cm-string {
            color: var(--stylix-base0B) !important;
          }

          .cm-comment {
            color: var(--stylix-base03) !important;
          }

          .cm-variable-2 {
            color: var(--stylix-base0A) !important;
          }

          .cm-def {
            color: var(--stylix-base0D) !important;
          }

          .cm-operator {
            color: var(--stylix-base05) !important;
          }

          .cm-keyword {
            color: var(--stylix-base08) !important;
          }

          .cm-atom {
            color: var(--stylix-base09) !important;
          }

          .cm-number {
            color: var(--stylix-base09) !important;
          }

          .cm-property {
            color: var(--stylix-base0D) !important;
          }

          .cm-builtin {
            color: var(--stylix-base09) !important;
          }

          .cm-variable-3 {
            color: var(--stylix-base09) !important;
          }
        '';
    };

    # Generate core-plugins.json
    home.file."${cfg.vaultPath}/.obsidian/core-plugins.json" = {
      force = true;
      source = jsonFormat.generate "obsidian-core-plugins.json" cfg.corePlugins;
    };

    # Generate community-plugins.json
    home.file."${cfg.vaultPath}/.obsidian/community-plugins.json" = {
      force = true;
      source = jsonFormat.generate "obsidian-community-plugins.json" cfg.communityPlugins;
    };

    # Generate daily-notes.json
    home.file."${cfg.vaultPath}/.obsidian/daily-notes.json" = {
      source = jsonFormat.generate "obsidian-daily-notes.json" {
        folder = cfg.dailyNotes.folder;
        format = cfg.dailyNotes.format;
        template = cfg.dailyNotes.template;
      };
    };

    # Generate templates.json
    home.file."${cfg.vaultPath}/.obsidian/templates.json" = {
      source = jsonFormat.generate "obsidian-templates.json" {
        folder = cfg.templates.folder;
      };
    };

    # Generate obsidian-local-rest-api plugin config
    home.file."${cfg.vaultPath}/.obsidian/plugins/obsidian-local-rest-api/data.json" =
      lib.mkIf cfg.restApi.enable
        {
          force = true;
          source = jsonFormat.generate "obsidian-local-rest-api.json" {
            apiKey = "";
            serverPort = cfg.restApi.port;
            serverHost = cfg.restApi.host;
            useSelfSignedCert = false;
            enableInsecureServer = cfg.restApi.enableInsecure;
            insecurePort = cfg.restApi.insecurePort;
          };
        };

    # Generate obsidian-livesync plugin config
    home.file."${cfg.vaultPath}/.obsidian/plugins/obsidian-livesync/data.json" =
      lib.mkIf cfg.livesync.enable
        {
          force = true;
          source = jsonFormat.generate "obsidian-livesync.json" {
            couchDB_URI = cfg.livesync.couchDB_URI;
            couchDB_USER = cfg.livesync.couchDB_USER;
            couchDB_PASSWORD = "";
            couchDB_DBNAME = cfg.livesync.couchDB_DBNAME;
            syncOnStart = cfg.livesync.syncOnStart;
            gcDelay = 0;
            periodicReplication = cfg.livesync.periodicReplication;
            syncOnFileOpen = cfg.livesync.syncOnFileOpen;
            encrypt = cfg.livesync.encrypt;
            passphrase = "";
            usePathObfuscation = cfg.livesync.usePathObfuscation;
            batchSave = cfg.livesync.batchSave;
            batch_size = 50;
            batches_limit = 50;
            useHistory = cfg.livesync.useHistory;
            disableRequestURI = true;
            customChunkSize = 50;
            syncAfterMerge = false;
            concurrencyOfReadChunksOnline = 100;
            minimumIntervalOfReadChunksOnline = 100;
            handleFilenameCaseSensitive = false;
            doNotUseFixedRevisionForChunks = false;
            settingVersion = 10;
            notifyThresholdOfRemoteStorageSize = 800;
          };
        };

    # Inject livesync secrets (CouchDB password, E2EE passphrase) from SOPS secrets
    # Each secret is handled independently if its file exists
    home.activation.injectLivesyncSecrets = lib.mkIf cfg.livesync.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PASSWORD=""
        PASSPHRASE=""
        [ -f "${cfg.livesync.couchDB_PASSWORD_FILE}" ] && PASSWORD="$(cat ${cfg.livesync.couchDB_PASSWORD_FILE} 2>/dev/null || true)"
        [ -f "${cfg.livesync.passphraseFile}" ] && PASSPHRASE="$(cat ${cfg.livesync.passphraseFile} 2>/dev/null || true)"
        DATA_FILE="${cfg.vaultPath}/.obsidian/plugins/obsidian-livesync/data.json"
        if [ -n "$PASSWORD" ] || [ -n "$PASSPHRASE" ]; then
          ${pkgs.jq}/bin/jq \
            --arg pwd "$PASSWORD" \
            --arg pp "$PASSPHRASE" \
            '.couchDB_PASSWORD = $pwd | .passphrase = $pp' \
            "$DATA_FILE" > "$DATA_FILE.tmp" \
            && mv "$DATA_FILE.tmp" "$DATA_FILE"
        fi
      ''
    );

    # Inject Obsidian API key from /run/secrets/ into the REST API plugin config
    home.activation.injectObsidianApiKey =
      lib.mkIf (cfg.restApi.enable && cfg.restApi.apiKeyFile != null)
        (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            API_KEY=$(cat ${cfg.restApi.apiKeyFile} 2>/dev/null || true)
            DATA_FILE="${cfg.vaultPath}/.obsidian/plugins/obsidian-local-rest-api/data.json"
            if [ -n "$API_KEY" ] && [ -f "$DATA_FILE" ]; then
              ${pkgs.jq}/bin/jq --arg key "$API_KEY" '.apiKey = $key' "$DATA_FILE" > "$DATA_FILE.tmp" \
                && mv "$DATA_FILE.tmp" "$DATA_FILE"
            fi
          ''
        );

    # Export Syncthing config for NixOS module to consume
    # This creates a marker that can be read by the NixOS Syncthing config
    home.sessionVariables = lib.mkIf cfg.syncthing.enable {
      OBSIDIAN_VAULT_PATH = cfg.vaultPath;
      OBSIDIAN_SYNCTHING_FOLDER_ID = cfg.syncthing.folderId;
    };

    # Create a helper script to export OBSIDIAN_API_KEY from the runtime secret
    home.file.".local/bin/set-obsidian-key" =
      lib.mkIf (cfg.restApi.enable && cfg.restApi.apiKeyFile != null)
        {
          executable = true;
          text = ''
            #!/bin/sh
            # Export OBSIDIAN_API_KEY from the runtime secret (decrypted by sops-nix)
            export OBSIDIAN_API_KEY="$(cat ${cfg.restApi.apiKeyFile})"
          '';
        };
  };
}
