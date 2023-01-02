{ config, lib, ... }: {
  networking.wireless = {
    enable = true;
    userControlled = {
      enable = true;
      group = "network";
    };
  };
  users.groups.network = {  };
}
