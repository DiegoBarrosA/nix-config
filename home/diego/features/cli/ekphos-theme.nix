{ config, lib, ... }:
let
  c = config.colorscheme.colors;
  scheme = config.colorscheme.type;

  cfgFile = "${config.home.homeDirectory}/.config/ekphos/config.toml";
in {
  xdg.configFile."ekphos/themes/${scheme}.toml".text = ''

    [base]
    background = "${c.base00}"
    background_secondary = "${c.base01}"
    foreground = "${c.base06}"
    muted = "${c.base03}"

    [accent]
    primary = "${c.base0D}"
    secondary = "${c.base0C}"

    [semantic]
    error = "${c.base08}"
    warning = "${c.base0A}"
    success = "${c.base0B}"
    info = "${c.base0C}"

    [ui]
    border = "${c.base03}"
    border_focused = "${c.base0D}"
    selection = "${c.base02}"
    cursor = "${c.base06}"

    [ui.statusbar]
    background = "${c.base01}"
    foreground = "${c.base06}"
    brand = "${c.base0D}"
    mode = "${c.base04}"
    separator = "${c.base02}"

    [ui.dialog]
    background = "${c.base01}"
    border = "${c.base0D}"
    title = "${c.base0D}"
    text = "${c.base05}"

    [ui.sidebar]
    background = "${c.base00}"
    item = "${c.base05}"
    item_selected = "${c.base0D}"
    folder = "${c.base0C}"
    folder_expanded = "${c.base0C}"

    [ui.content]
    background = "${c.base00}"
    text = "${c.base06}"
    heading1 = "${c.base0D}"
    heading2 = "${c.base0B}"
    heading3 = "${c.base0A}"
    heading4 = "${c.base0C}"
    link = "${c.base0D}"
    link_invalid = "${c.base08}"
    code = "${c.base0B}"
    code_background = "${c.base01}"
    blockquote = "${c.base03}"
    list_marker = "${c.base0C}"

    [ui.outline]
    background = "${c.base00}"
    heading1 = "${c.base0D}"
    heading2 = "${c.base0B}"
    heading3 = "${c.base0A}"
    heading4 = "${c.base0C}"

    [ui.search]
    background = "${c.base01}"
    border = "${c.base0D}"
    input = "${c.base05}"
    match_highlight = "${c.base0A}"
    match_current = "${c.base09}"
    match_count = "${c.base04}"

    [ui.editor]
    heading1 = "${c.base0D}"
    heading2 = "${c.base0B}"
    heading3 = "${c.base0A}"
    heading4 = "${c.base0C}"
    heading5 = "${c.base0C}"
    heading6 = "${c.base04}"
    code = "${c.base0B}"
    link = "${c.base0D}"
    blockquote = "${c.base04}"
    list_marker = "${c.base0C}"
    bold = "${c.base0A}"
    italic = "${c.base0C}"
  '';

  home.activation.ekphosTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${cfgFile}" ]; then
      run sed -i 's|^theme *= *".*"|theme = "${scheme}"|' "${cfgFile}"
    fi
  '';
}