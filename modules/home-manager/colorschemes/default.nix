# Locally defined base16 palettes, looked up by `colorscheme.type` before
# nix-colors is consulted. Same shape as a nix-colors palette: base00 to base0F
# as bare hex strings.
{
  monochrome-dark = import ./monochrome-dark.nix;
  monochrome-light = import ./monochrome-light.nix;
}
