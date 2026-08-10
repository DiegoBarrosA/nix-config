# Monochrome light: the light counterpart to monochrome-dark.nix.
#
# Same idea, opposite pole. No hue anywhere, so meaning is still carried by
# brightness, but on a light background "loud" means darker, not lighter.
# Two ladders do the work:
#
#   surfaces  base00 -> base03  near-white down to the first legible gray
#   text      base04 -> base08  secondary text down to maximum emphasis
#
# The accent slots are ordered by how loud the thing they mark should be,
# darkest (loudest) first, mirroring monochrome-dark's brightest-first order
# so the two schemes read as inverses of each other. base08 is true black,
# the same convergence point the dark scheme gives to true white.
#
# Values are bare hex without a leading '#', matching the nix-colors palettes
# this sits alongside.
{
  # Surfaces
  base00 = "f5f5f5"; # background
  base01 = "ebebeb"; # panels, inactive surfaces, status bar background
  base02 = "d9d9d9"; # selection background
  base03 = "999999"; # comments, disabled text, borders

  # Text
  base04 = "757575"; # secondary text
  base05 = "555555"; # default text
  base06 = "212121"; # bright (emphasized) text
  base07 = "0a0a0a"; # darkest text

  # Accents, darkest (loudest) first: the ordering is the design, not the
  # values. Everything below base05 is meant to pull the eye, everything
  # above it to recede. Diff colours land either side of plain text on
  # purpose, so a patch still reads at a glance: deletions blazing, additions
  # clearly lifted.
  base08 = "000000"; # errors, urgent, deletions, variables
  base0D = "111111"; # functions and the UI accent (focus, selection)
  base09 = "222222"; # warnings, numbers, constants
  base0B = "333333"; # strings, additions
  base0A = "404040"; # search matches, classes, highlights
  base0E = "4b4b4b"; # keywords, mode indicator
  base0C = "666666"; # support, regex, escapes
  base0F = "909090"; # deprecated, punctuation
}
