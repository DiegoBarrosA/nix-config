{ ... }:
{
  flake.modules.homeManager.desktop-sway-kanshi =
{
  config,
  lib,
  pkgs,
  ...
}:
let
  enableKanshi = lib.attrByPath [ "rubi" "desktop" "manageKanshi" ] true config;
in
lib.mkIf enableKanshi {
  services.kanshi = {
    enable = true;

    settings = [
      {
        profile.name = "docked";
        profile.outputs = [
          {
            criteria = "Lenovo Group Limited 0x403C Unknown";
            status = "disable";
          }
          {
            criteria = "GWD ARZOPA *";
            position = "0,0";
            scale = 1.25;
            transform = "90";
          }
          {
            criteria = "Samsung Electric Company LS27A600U *";
            position = "864,40";
            scale = 1.0;
          }
        ];
      }

      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "Lenovo Group Limited 0x403C Unknown";
            position = "0,0";
            scale = 1.0;
          }
        ];
      }
    ];
  };
};
}
