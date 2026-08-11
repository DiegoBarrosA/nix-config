{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # No IBM Plex Nerd Font variant exists upstream; symbols-only is the
    # generic icon-glyph fallback for pairing with any un-patched font.
    nerd-fonts.symbols-only
    font-awesome
    source-han-mono
    source-han-sans

    # Covers general Unicode symbol blocks (Misc Symbols and Arrows,
    # Geometric Shapes, Dingbats) that Nerd Fonts doesn't patch.
    noto-fonts
  ];
}
