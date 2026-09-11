{
  config,
  lib,
  ...
}:
let
  inherit (config.stylix) fonts;

  family = lib.removeSuffix "*" fonts.sansSerif.name;

  # Base text size in points, derived from the Stylix terminal size (20 -> 7).
  base = (fonts.sizes.terminal + 1) / 3;

  offsets = {
    "very small" = -2;
    smaller = -3;
    small = -1;
    normal = 0;
    big = 4;
    large = 7;
    larger = 12;
    huger = 20;
    massive = 41;
  };

  keys = [
    "very small"
    "smaller"
    "small"
    "normal"
    "big"
    "large"
    "larger"
    "huger"
    "massive"
  ];

  pairs = lib.concatLists (
    map (k: [
      {
        name = "${k} font";
        value = "${family}  ${toString (base + offsets.${k})}";
      }
      {
        name = "${k} bold font";
        value = "bold ${family}  ${toString (base + offsets.${k})}";
      }
      {
        name = "${k} italic font";
        value = "italic ${family}  ${toString (base + offsets.${k})}";
      }
    ]) keys
  );

  seds = lib.concatStringsSep "\n" (
    map (p: ''
      sed -i 's|<Option name="${p.name}" value="[^"]*"/>|<Option name="${p.name}" value="${p.value}"/>|' "$ui"
    '') pairs
  );
in
{
  # ui_config is app-managed, so patch it in place (same pattern as the old
  # reaper.ini tweak) instead of shipping a static copy that would be discarded.
  home.activation.mixbusFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ui="''${XDG_CONFIG_HOME:-$HOME/.config}/mixbus12/ui_config"
    if [ -f "$ui" ]; then
      ${seds}
    fi
  '';
}
