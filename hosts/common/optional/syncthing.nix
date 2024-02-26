{ config, lib, pkgs, ... }: {
  services.syncthing = {
    user = "diego";
    enable = true;
    dataDir = "/storage/var/lib/syncthing";
    devices = {
      grafito = {
         addresses =
           [ "tpc://172.104.25.144:22067" ];
         id = "3XRAM24-CGCNGD6-G3LVYDX-7PHGELD-LKSJI2V-N6CE6VZ-4SEEMLB-MT26ZQP ";
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
        devices = [ "grafito" ];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };
      "/storage/var/lib/syncthing/Pictures" = {

        label = "Pictures";
        id = "funvf-mshvj";
        devices = [ "grafito"];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };
      "/storage/var/lib/syncthing/DCIM" = {

        label = "Photos";
        id = "hxhki-jlpft";
        devices = [ "lazulita" ];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };
      "/storage/var/lib/syncthing/Books" = {

        label = "Books";
        id = "h5zna-wjyt2";
        devices = [ "grafito"];
        versioning = {
          type = "simple";
          params.keep = "10";
        };

      };

    };

  };

}
