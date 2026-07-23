# Selects the active desktop environment from the `desktop` specialArg
# (set per host in flake.nix via mkHost). The import path is the mapping:
#   desktop = "sway" -> environments/sway.nix + features/desktop/sway (home)
# Hosts with no desktop (servers) pass desktop = null and import nothing here.
{ lib, desktop ? null, ... }:
{
  imports = lib.optionals (desktop != null) [
    ./desktop-common.nix
    ./environments/${desktop}.nix
  ];
}
