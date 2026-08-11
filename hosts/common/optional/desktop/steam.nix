{
  lib,
  pkgs,
  ...
}:
{
  hardware.graphics.enable32Bit = true;
  programs.steam = {
    enable = true;
    extest.enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        desiredgov = "performance";
        igpu_desiredgov = "performance";
      };
    };
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
  ];
}
