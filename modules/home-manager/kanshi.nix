{ lib, config, pkgs, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.kanshi;
in
{
  options.kanshi = mkEnableOption "Kanshi display manager configuration";

  config = lib.mkIf cfg {
    # Kanshi is managed through services.kanshi in Home Manager
    # This module just provides a wrapper for easier access
  };
}
