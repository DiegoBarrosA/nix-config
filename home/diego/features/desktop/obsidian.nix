{
  config,
  lib,
  ...
}:
{
  programs.obsidian = {
    enable = true;
    cli.enable = true;

    vaults.notes = {
      target = "Notes";

      settings = {
        app = {
          vimMode = true;
          showLineNumber = true;
          showInlineTitle = false;
          alwaysUpdateLinks = true;
          newFileLocation = "folder";
          newFileFolderPath = "Quick notes";
          attachmentFolderPath = "Attachments";
          openBehavior = "daily";
          cli.enable = true;
          pdfExportSettings = {
            pageSize = "Letter";
            landscape = false;
            margin = "0";
            downscalePercent = 100;
          };
        };

        appearance = {
          theme = "obsidian";
          showViewHeader = true;
          showRibbon = false;
          nativeMenus = false;
        };

        extraFiles."community-plugins.json".text = builtins.toJSON [
          "obsidian-excalidraw-plugin"
          "dataview"
          "templater-obsidian"
          "obsidian-minimal-settings"
          "obsidian-style-settings"
        ];
      };
    };
  };

  stylix.targets.obsidian = {
    enable = true;
    vaultNames = [ "notes" ];
  };

  programs.obsidian.vaults.notes.settings.appearance = {
    interfaceFontFamily = lib.mkForce config.stylix.fonts.sansSerif.name;
    textFontFamily = lib.mkForce config.stylix.fonts.monospace.name;
  };

  home.sessionVariables = {
    OBSIDIAN_VAULT_PATH = "${config.home.homeDirectory}/Notes";
    OBSIDIAN_SYNCTHING_FOLDER_ID = "obsidian-notes";
  };
}
