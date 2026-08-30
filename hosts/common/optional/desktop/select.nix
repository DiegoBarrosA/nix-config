{ lib, desktop ? null, ... }:
{
  imports = lib.optionals (desktop != null) [
    ./desktop-common.nix
    ./environments/${desktop}.nix
  ];
}
