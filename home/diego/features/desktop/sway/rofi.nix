{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
  # Passing a font file path lets rofi skip the slow Pango/Fontconfig lookup
  # (~120ms) and load the font directly via Harfbuzz/Cairo.
  monoFont = "${pkgs.fantasque-sans-mono}/share/fonts/opentype/FantasqueSansMono-Regular.otf";
in
{
  xdg.configFile = {
    "rofi/config.rasi".text = ''
      @theme "theme.rasi"

      configuration {
        show-icons: false;
        terminal: "alacritty";
        font: "Jost* 24";
        drun-use-desktop-cache: true;
        matching: "fuzzy";
      }
    '';

    "rofi/theme.rasi".text = ''
      * {
          bg:      #${colors.base01}FF;
          bg-alt:  #${colors.base01}FF;
          fg:      #${colors.base05}FF;
          accent:  #${colors.base0D}FF;
          urgent:  #${colors.base08}FF;
          match:   #${colors.base04}FF;
          border:  #${colors.base03}FF;

          background-color: transparent;
          text-color:       @fg;
          spacing:          0;
      }

      window {
          background-color: @bg;
          border:           2px;
          border-color:     @border;
          border-radius:    10px;
          width:            40%;
          padding:          0;
      }

      mainbox {
          children: [ inputbar, message, listview ];
          background-color: @bg;
      }

      inputbar {
          children: [ prompt, entry ];
          font: "${monoFont} 32";

          background-color: @bg;
          padding: 12px;
      }

      prompt {
          font: "Font Awesome 7 Free Solid 32";
          background-color: @bg;
          text-color:       @fg;
          padding:          4px 8px;
          margin:           0;
      }

      entry {
          background-color: @bg-alt;
          text-color:       @fg;
          padding:          4px 8px;
          placeholder:      "Type to search...";
          placeholder-color: @match;
      }

      message {
          background-color: @bg;
          padding: 0;
      }

      textbox {
          background-color: @bg;
      }

      listview {
          lines:     8;
          columns:   1;
          fixed-height: true;
          background-color: @bg;
          padding:  10;
          scrollbar:        false;
          fixed-height: false; 
          dynamic: true;
      }

      element {
          padding:          8px 12px;
          background-color: @bg;
          text-color:       @fg;
      }

      element selected {
          background-color: @bg;
          text-color:       @accent;
      }

      element-text {
          background-color: inherit;
          text-color:       inherit;
      }

      element-icon {
          background-color: transparent;
          text-color:       @fg;
      }

      element urgent {
          text-color: @urgent;
      }
    '';
  };
}
