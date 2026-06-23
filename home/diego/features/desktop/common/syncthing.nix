{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Syncthing service via Home Manager
  # Syncs with cobalto (folder IDs must match hosts/common/optional/syncthing.nix)

  services.syncthing = {
    enable = true;
    settings = {
      devices = {

        cobalto = {
          addresses = [
            "http://syncthing.minerales.network"
          ];
          id = "OBBQD3A-GPIECSP-BYZTCEE-ENGRG6E-Q4QIFPA-RGR74HJ-BOLCQJM-MNKK4AK";
        };
        "grafito" = {
          id = "F45OBX5-WV6KPLK-KDJYFG6-HVQ5UNQ-STLATVV-FTFNTGI-NR4M25E-BZAKTQH";
        };
        "lonsdaleita" = {
          id = "5SMKMOV-TXWSXW7-4L3PHZ6-6DKMXS4-SSOFD2Y-JJ4RXQ5-WY7JT3F-VI4ARAK";
        };

      };
      folders = {
        "${config.home.homeDirectory}/Music" = {
          id = "media-music";
          devices = [ "cobalto" ];
        };
        "${config.home.homeDirectory}/Books" = {
          id = "media-books";
          devices = [ "cobalto" ];
        };
        "${config.home.homeDirectory}/Audiobooks" = {
          id = "media-audiobooks";
          devices = [ "cobalto" ];
        };
        "${config.home.homeDirectory}/Documents" = {
          id = "media-documents";
          devices = [ "cobalto" ];
        };
        "${config.home.homeDirectory}/Notes" = {
          id = "media-obsidian";
          devices = [ "cobalto" ];
        };
        "${config.home.homeDirectory}/Projects" = {
          id = "media-projects";
          devices = [ "cobalto" ];
        };
        "${config.home.homeDirectory}/Pictures" = {
          id = "media-pictures";
          devices = [ "cobalto" ];
        };
      };
    };
  };

  home.packages = with pkgs; [
    syncthing
  ];

  home.file.".config/syncthing/.stfolder".text = "";

  # Ensure Sync and Obsidian dirs exist (capitalized; Pictures has Wallpapers, Photos, Screenshots)
  home.activation.createSyncthingDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Sync"/{Music,Books,Documents,Pictures,Notes}
    mkdir -p "${config.home.homeDirectory}/Sync/Pictures"/{Wallpapers,Photos,Screenshots}
  '';

  xdg.userDirs.extraConfig = {
    OBSIDIAN = "${config.home.homeDirectory}/Notes";
  };
  xdg.userDirs.setSessionVariables = false;
}
