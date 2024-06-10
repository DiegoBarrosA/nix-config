{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.wpa_supplicant_gui ];
  networking.wireless = {
    enable = true;
    userControlled = {
      enable = true;
      group = "network";
    };

    allowAuxiliaryImperativeNetworks = true;
    extraConfig = ''
      update_config=1
    '';
  };
  # Ensure group exists
  users.groups.network = { };
}
