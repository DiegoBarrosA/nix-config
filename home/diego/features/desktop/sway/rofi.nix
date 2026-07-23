{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  xdg.configFile = {
    "rofi/config.rasi".text = ''
      @theme "theme.rasi"

      configuration {
        show-icons: false;
        terminal: "alacritty";
        font: "${config.stylix.fonts.monospace.name} 20";
      }
    '';

    "rofi/theme.rasi".text = ''
      * {
          bg:      #${colors.base01}FF;
          bg-alt:  #${colors.base02}FF;
          fg:      #${colors.base04}FF;
          accent:  #${colors.base0D}FF;
          urgent:  #${colors.base08}FF;
          match:   #${colors.base0C}FF;
          border:  #${colors.base03}FF;

          background-color: transparent;
          text-color:       @fg;
          spacing:          0;
      }

      window {
          background-color: @bg;
          border:           2px;
          border-color:     @border;
          border-radius:    0px;
          width:            50%;
          padding:          0;
      }

      mainbox {
          children: [ inputbar, message, listview ];
          background-color: @bg;
      }

      inputbar {
          children: [ prompt, entry ];
          background-color: @bg;
          padding: 12px;
      }

      prompt {
          background-color: @accent;
          text-color:       @bg;
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
          padding:  0;
          scrollbar:        false;
      }

      element {
          padding:          8px 12px;
          background-color: @bg;
          text-color:       @fg;
      }

      element normal normal {
          background-color: @bg;
          text-color:       @fg;
      }

      element normal alternate {
          background-color: @bg;
          text-color:       @fg;
      }

      element selected normal {
          background-color: @accent;
          text-color:       @bg;
      }

      element selected alternate {
          background-color: @accent;
          text-color:       @bg;
      }

      element-text normal normal {
          background-color: @bg;
          text-color:       @fg;
      }

      element-text normal alternate {
          background-color: @bg;
          text-color:       @fg;
      }

      element-text selected normal {
          background-color: @accent;
          text-color:       @bg;
      }

      element-text selected alternate {
          background-color: @accent;
          text-color:       @bg;
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
