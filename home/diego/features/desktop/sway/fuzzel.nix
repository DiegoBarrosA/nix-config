{ config, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        dpi-aware = "no";
        prompt = " ‎ ";
        font = "${config.stylix.fonts.monospace.name}:weight=regular:size=27,Font Awesome 7 Free:style=Solid:size=27";
        line-height = 40;
        width = 50;
        fields = "name,generic,comment,categories,filename,keywords";
        terminal = "alacritty";
        show-actions = "no";
        exit-on-keyboard-focus-loss = "no";
        icons-enabled = "no";
        inner-pad = 10;
        lines = 10;
        horizontal-pad = 40;
        vertical-pad = 40;
        layer = "overlay";
      };

      colors = {
        background = "${colors.base01}ff";
        text = "${colors.base04}ff";
        match = "${colors.base0C}ff";
        selection = "${colors.base01}ff";
        selection-text = "${colors.base0D}ff";
        selection-match = "${colors.base0A}ff";
        border = "${colors.base0D}ff";
        prompt = "${colors.base05}ff";
        input = "${colors.base05}ff";
      };

      border = {
        radius = 0;
        width = 2;
      };

      dmenu = {
        exit-immediately-if-empty = "yes";
      };
    };
  };

  xdg.configFile."raffi/raffi.yaml".text = ''
    version: 1

    general:
      ui_type: fuzzel

    launchers:
      terminal:
        binary: alacritty
        description: "Terminal"
        icon: utilities-terminal

      firefox:
        binary: firefox-devedition
        description: "Firefox Dev Edition"
        icon: firefox

      thunderbird:
        binary: thunderbird
        description: "Thunderbird Mail"
        icon: thunderbird

      obsidian:
        binary: obsidian
        description: "Obsidian"
        icon: obsidian

      code:
        binary: code-cursor-fhs
        description: "Cursor IDE"
        icon: code-cursor

      file-manager:
        binary: alacritty
        args: ["-e", "yazi"]
        description: "File Manager (yazi)"
        icon: system-file-manager

      lock:
        binary: swaylock
        args: ["-f"]
        description: "Lock Screen"
        icon: system-lock-screen
        ifenvset: WAYLAND_DISPLAY

    addons:
      calculator:
        enabled: true
      web_searches:
        - name: "Google"
          keyword: "g"
          url: "https://www.google.com/search?q={query}"
          icon: google
        - name: "GitHub"
          keyword: "gh"
          url: "https://github.com/search?q={query}"
          icon: github
        - name: "NixOS Packages"
          keyword: "np"
          url: "https://search.nixos.org/packages?query={query}"
          icon: nix-snowflake
  '';
}
