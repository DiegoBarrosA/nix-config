{ ... }:
{
  flake.modules.homeManager.cli-rmpc =
    { config, pkgs, ... }:
    let
      c = config.colorscheme.colors;
      assets = "${pkgs.rmpc.src}/assets";

      # Stylix has no rmpc target. Start from the theme and config that ship
      # with this rmpc version and patch them, so they track rmpc upgrades.
      theme = pkgs.runCommand "rmpc-stylix-theme.ron" { } ''
        sed \
          -e 's|background_color: None|background_color: "#${c.base00}"|' \
          -e 's|text_color: None|text_color: "#${c.base05}"|' \
          -e 's|^    lyrics: (|    cava: (\n        bg_color: "#${c.base00}",\n        bar_color: Gradient({0: "#${c.base0B}", 50: "#${c.base0A}", 100: "#${c.base08}"}),\n    ),\n&|' \
          -e 's|"light_green"|"#${c.base0B}"|g' \
          -e 's|"blue"|"#${c.base0D}"|g' \
          -e 's|"yellow"|"#${c.base0A}"|g' \
          -e 's|"green"|"#${c.base0B}"|g' \
          -e 's|"red"|"#${c.base08}"|g' \
          -e 's|"magenta"|"#${c.base0E}"|g' \
          -e 's|"white"|"#${c.base05}"|g' \
          -e 's|"black"|"#${c.base00}"|g' \
          ${assets}/example_theme.ron > $out
      '';

      # Alacritty has no image protocol, and ueberzugpp rendered misaligned, so use the block renderer.
      # Cava replaces the lyrics pane under the album art, and also gets its own tab on key 8.
      rmpcConfig = pkgs.runCommand "rmpc-config.ron" { } ''
        sed -z \
          -e 's|theme: None,|theme: "stylix",|' \
          -e 's|method: Auto,|method: Block,|' \
          -e 's|auto_open_downloads: true,|&\n    cava: (input: (method: Pipewire, source: "auto")),|' \
          -e 's|size: "7",\(\n[^\n]*\n[^\n]*\n[^\n]*\)Lyrics\([^\n]*\n[^\n]*\n[^\n]*\)Pane(Lyrics)|size: "12",\1Cava\2Pane(Cava)|' \
          -e 's|\(\n *\)"7": *SwitchToTab("Search"),|&\1"8": SwitchToTab("Cava"),|' \
          -e 's|    \],\n)|        (\n            name: "Cava",\n            borders: "ALL",\n            border_symbols: Rounded,\n            pane: Pane(Cava),\n        ),\n&|' \
          ${assets}/example_config.ron > $out
      '';
    in
    {
      home.packages = [
        pkgs.cava
      ];

      services.mpd = {
        enable = true;
        musicDirectory = "${config.home.homeDirectory}/Music";
        network.listenAddress = "127.0.0.1";
        extraConfig = ''
          audio_output {
            type "pipewire"
            name "PipeWire"
          }
        '';
      };

      # Exposes MPD over MPRIS so playerctl and media keys control it.
      services.mpd-mpris.enable = true;

      programs.rmpc.enable = true;

      xdg.configFile."rmpc/config.ron".source = rmpcConfig;
      xdg.configFile."rmpc/themes/stylix.ron".source = theme;
    };
}
