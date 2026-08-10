# Monochrome dark: a base16 scheme with no hue at all.
#
# Every slot is a neutral gray, so meaning has to be carried by brightness
# instead of colour. Two ladders do that work:
#
#   surfaces  base00 -> base03  near-black up to the first legible gray
#   text      base05 -> base08  plain text up to maximum emphasis
#
# The accent slots are ordered by how loud the thing they mark should be, which
# keeps status indicators readable once red and green are gone. In waybar terms
# that is off (base03) < ok (base05) < warning (base09) < error (base08), a
# clear ramp from recessive to unmissable.
#
# Values are bare hex without a leading '#', matching the nix-colors palettes
# this sits alongside.
{
  # Surfaces
  base00 = "0a0a0a"; # background (set to 000000 for true black on OLED)
  base01 = "161616"; # panels, inactive surfaces, status bar background
  base02 = "262626"; # selection background
  base03 = "666666"; # comments, disabled text, borders

  # Text
  base04 = "8a8a8a"; # secondary text
  base05 = "aaaaaa"; # default text
  base06 = "dedede"; # bright text
  base07 = "f5f5f5"; # lightest text and light backgrounds

  # Accents, brightest first: the ordering is the design, not the values.
  # Everything above base05 is meant to pull the eye, everything below it to
  # recede. Diff colours land either side of plain text on purpose, so a patch
  # still reads at a glance: deletions blazing, additions clearly lifted.
  base08 = "ffffff"; # errors, urgent, deletions, variables
  base0D = "eeeeee"; # functions and the UI accent (focus, selection)
  base09 = "dddddd"; # warnings, numbers, constants
  base0B = "cccccc"; # strings, additions
  base0A = "c0c0c0"; # search matches, classes, highlights
  base0E = "b4b4b4"; # keywords, mode indicator
  base0C = "999999"; # support, regex, escapes
  base0F = "6e6e6e"; # deprecated, punctuation
}
