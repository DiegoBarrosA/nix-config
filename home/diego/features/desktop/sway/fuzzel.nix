{ config, lib, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.fuzzel = {
    enable = true;

    settings.main = {
      # Stylix generates `prompt =` (empty value) which is a parse error in fuzzel.
      # Set an explicit value to override the broken Stylix template output.
      prompt = ">‎ ‎ ";
      terminal = "alacritty -e";
      layer = "overlay";
      lines = 12;
      width = 50;
      font = lib.mkForce "${config.fontProfiles.monospace.family}:size=14";
      icons-enabled = false;
      vertical-pad = 30;

    };
    settings.colors = {
      selection-text = lib.mkForce "${colors.base0D}ff";
      selection = lib.mkForce "${colors.base00}ff";
    };

    settings.border = {
      radius = 0;
      width = 2;
    };
  };
}
