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

      # Unplugging the dock drops the monitors one at a time. Without these,
      # the half-unplugged state matches nothing and eDP-1 stays disabled.
      {
        profile.name = "partial-arzopa";
        profile.outputs = [
          {
            criteria = "Lenovo Group Limited 0x403C Unknown";
            position = "0,0";
            scale = 1.0;
          }
          { criteria = "GWD ARZOPA *"; }
        ];
      }

      {
        profile.name = "partial-samsung";
        profile.outputs = [
          {
            criteria = "Lenovo Group Limited 0x403C Unknown";
            position = "0,0";
            scale = 1.0;
          }
          { criteria = "Samsung Electric Company LS27A600U *"; }
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
