{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.syncthing = {
    enable = true;
    user = "diego";
    dataDir = "/home/diego/.syncthing";
    configDir = "/home/diego/.config/syncthing";

    openDefaultPorts = true;

    guiAddress = "0.0.0.0:8384";

    guiPasswordFile = config.sops.secrets."syncthing-password".path;

    settings = {
      gui = {
        theme = "dark";
        insecureAdminAccess = false;
        user = "diego";
      };

      options = {
        urAccepted = -1;
        crashReportingEnabled = false;
        globalAnnounceEnabled = true;
        localAnnounceEnabled = true;
        natEnabled = true;
        startBrowserEnabled = false;
      };

      devices = {
        "rubi" = {
          id = "O5A33WF-VWBNZ5T-LY27HY7-EIDGGVX-YKCWSDO-PWCZCVV-CTBLHHY-AFQHQQV";
        };
        "grafito" = {
          id = "F45OBX5-WV6KPLK-KDJYFG6-HVQ5UNQ-STLATVV-FTFNTGI-NR4M25E-BZAKTQH";
        };
        "agata" = {
          id = "PKXTHLD-NZSC2R7-YAQSFP6-X64RLPW-NWOGH2S-KIL2UL6-6HTPQDA-EDJPZAO";
        };
        "jade" = {
          id = "TB4RVRK-FGAN262-IFIOVLA-HDQQCHS-OXVFYXC-TJNLGYC-TXEOISC-QIRK7A2";
        };
        "lonsdaleita" = {
          id = "5SMKMOV-TXWSXW7-4L3PHZ6-6DKMXS4-SSOFD2Y-JJ4RXQ5-WY7JT3F-VI4ARAK";
        };

      };

      folders = {
        "media-projects" = {
          path = "/mnt/media/Projects";
          devices = [ "rubi" ];
        };

        "media-documents" = {
          path = "/mnt/media/Documents";
          devices = [
            "grafito"
            "jade"
            "rubi"
          ];
        };

        "media-obsidian" = {
          path = "/mnt/media/Obsidian/obsidiana";
          devices = [
            "grafito"
            "jade"
            "rubi"
          ];
        };

        "media-music" = {
          path = "/mnt/media/Music";
          devices = [
            "agata"
            "rubi"
          ];
        };

        "media-pictures" = {
          path = "/mnt/media/Pictures";
          devices = [
            "grafito"
            "jade"
            "rubi"
          ];
        };

        "media-books" = {
          path = "/mnt/media/Books";
          devices = [ "rubi" ];
        };

        "media-audiobooks" = {
          path = "/mnt/media/Audiobooks";
          devices = [ "rubi" ];
        };

      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/media/Music 0755 diego diego -"
    "d /mnt/media/Books 0755 diego diego -"
    "d /mnt/media/Audiobooks 0755 diego diego -"
    "d /mnt/media/Documents 0755 diego diego -"
    "d /mnt/media/Obsidian 0755 diego diego -"
    "d /mnt/media/Projects 0755 diego diego -"
    "d /mnt/media/Archive 0755 diego diego -"
    "d /mnt/media/Pictures 0755 diego diego -"
    "d /mnt/media/Pictures/Wallpapers 0755 diego diego -"
    "d /mnt/media/Pictures/Photos 0755 diego diego -"
    "d /mnt/media/Pictures/Screenshots 0755 diego diego -"
  ];

  networking.firewall = {
    allowedTCPPorts = [
      8384
      22000
    ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };
}
