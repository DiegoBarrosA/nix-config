{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.obsidian-vault = {
    enable = true;
    vaultPath = "${config.home.homeDirectory}/Notes";
    # Settings from your existing config
    settings = {
      vimMode = true;
      showLineNumber = true;
      showInlineTitle = false;
      alwaysUpdateLinks = true;
      newFileLocation = "folder";
      newFileFolderPath = "Quick notes";
      attachmentFolderPath = "Attachments";
      openBehavior = "daily";
      pdfExportSettings = {
        pageSize = "Letter";
        landscape = false;
        margin = "0";
        downscalePercent = 100;
      };
    };
    appearance = {
      theme = "moonstone";
      accentColor = "#828282";
      baseFontSize = 26;
      showViewHeader = true;
      showRibbon = false;
      nativeMenus = false;
      stylixTheme = true;
    };
    communityPlugins = [
      "obsidian-excalidraw-plugin"
      "dataview"
      "templater-obsidian"
      "obsidian-local-rest-api"
      "obsidian-minimal-settings"
      "obsidian-style-settings"
      "obsidian-livesync"
    ];
    # Daily notes configuration
    dailyNotes = {
      folder = "Daily";
      format = "YYYY/MM-MMMM/YYYY-MM-DD";
      template = "Templates/Daily";
    };
    # Templates configuration
    templates.folder = "Templates";
    restApi = {
      enable = true; # For MCP integration
      host = "0.0.0.0"; # Reachable from cobalto via Tailscale
      apiKeyFile = "/run/secrets/obsidian-api-key";
    };
    syncthing = {
      enable = true;
      folderId = "obsidian-notes";
      devices = [
        "grafito"
        "jade"
      ];
    };
    livesync = {
      enable = true;
      couchDB_URI = "https://sync.minerales.network";
      couchDB_USER = "admin";
      couchDB_PASSWORD_FILE = "/run/secrets/couchdb-admin-password";
      passphraseFile = "/run/secrets/obsidian-livesync-passphrase";
      encrypt = false;
    };
  };
}
