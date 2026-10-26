{ ... }:
{
  flake.modules.homeManager.kanshi =
{ lib, config, pkgs, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.kanshi;
in
{
  options.kanshi = mkEnableOption "Kanshi display manager configuration";

  config = lib.mkIf cfg {

  };
};
}
