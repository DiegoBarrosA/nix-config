{ config, lib, pkgs, ... }: {
  services.syncthing = {
    user = "diego";
    enable = true;
    dataDir = "/storage/var/lib/syncthing";
    devices = {
      indigo = {
        addresses = [ "tcp://177.200.204.220:22067" ];
        id = "ZNXAK2H-4H4OHMP-COATSSF-3F2ETZK-ZON5DML-TUJP7OU-TJGCDQR-UCYCKAK";
      };
      lazulita = {
        addresses = [ "tcp://177.200.204.220:22067" ];
        id = "4NTQYGX-EETMOVL-APAXXXE-6TDED7K-PQAWS7Q-M6SGA4F-B6ADEVQ-Y3EHCQO";
      };

    };
    folders = {
      "/storage/var/lib/syncthing/data" = {
        label = "Data";
        id = "b15nx-kwce4";
        devices = [ "indigo" ];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };
      "/storage/var/lib/syncthing/Pictures" = {

        label = "Pictures";
        id = "funvf-mshvj";
        devices = [ "indigo" ];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };
      "/storage/var/lib/syncthing/DCIM" = {

        label = "Photos";
        id = "hxhki-jlpft";
        devices = [ "indigo" "lazulita" ];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };
      "/storage/var/lib/syncthing/Books" = {

        label = "Books";
        id = "h5zna-wjyt2";
        devices = [ "indigo" ];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };

    };

  };

}
