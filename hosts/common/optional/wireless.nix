{ config, lib, ... }: {
  # Wireless secrets stored through sops
  sops.secrets."wireless.env" = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    # Declarative
    environmentFile = config.sops.secrets."wireless.env".path;
    networks = { "@home_uuid@" = { pskRaw = "@home_psk@"; }; };

    # Imperative
    #   allowAuxiliaryImperativeNetworks = true;
    userControlled = {
      enable = true;
      group = "network";
    };
    extraConfig = ''
      update_config=1
    '';
  };

  # Ensure group exists
  users.groups.network = { };
}
