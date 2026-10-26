{ ... }:
{
  flake.modules.homeManager.desktop-sway-overview =
{ pkgs, customPkgs, ... }:
let
  # windows prints the toplevel identifier of the chosen window; map it back to
  # a sway con_id (sway >= 1.12 exposes foreign_toplevel_identifier in the tree).
  win-overview = pkgs.writeShellScriptBin "win-overview" ''
    # second press closes the overlay (pkill -x: exact name, never matches this script)
    ${pkgs.procps}/bin/pkill -x windows && exit 0

    out=$(swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
    id=$(${customPkgs.windows-overview}/bin/windows -o "$out") || exit 0
    [ -n "$id" ] || exit 0
    con=$(swaymsg -t get_tree | ${pkgs.jq}/bin/jq --arg id "$id" '.. | objects | select(.foreign_toplevel_identifier == $id) | .id')
    [ -n "$con" ] && swaymsg "[con_id=$con] focus"
  '';
in
{
  home.packages = [ win-overview ];

  wayland.windowManager.sway.config.keybindings = {
    "Mod4+Tab" = "exec win-overview";
    "Mod4+Shift+Tab" = "workspace next";
    "Mod4+Ctrl+Tab" = "workspace prev";
  };
};
}
