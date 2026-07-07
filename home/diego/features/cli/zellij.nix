{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.zellij = {
    enable = true;
    # Note: enableNushellIntegration doesn't exist in home-manager yet
    # Zellij integration is handled manually in nushell.nix via Ctrl+T keybinding
    #
    # NOTE: We use an explicit flat-format material-darker theme here instead of
    # Stylix's generated `stylix` theme. Zellij 0.44's tab-bar falls back to a
    # hard-coded lime-green for the active tab when the flat color fields
    # (fg/bg/green/...) are absent, which the Stylix structured theme omits.
    # bat/helix and other programs are still themed by Stylix.
    settings = {
      default_shell = "nu";

      show_startup_tips = false;
      pane_frames = false;
      mouse_mode = true;
      simplified_ui = true;
      theme = "material-darker";
      copy_command = "wl-copy";
      scrollback_editor = "${pkgs.helix}/bin/hx";
      copy_on_select = false;
      themes = {
        material-darker = {
          fg = "#${colors.base05}";
          # Tab bar + status (keybindings) bar background. Use base01 so the
          # bars sit slightly lighter than the terminal background (base00).
          bg = "#${colors.base01}";
          black = "#${colors.base00}";
          red = "#${colors.base08}";
          green = "#${colors.base0B}";
          yellow = "#${colors.base0A}";
          blue = "#${colors.base0D}";
          magenta = "#${colors.base0E}";
          cyan = "#${colors.base0C}";
          white = "#${colors.base05}";
          orange = "#${colors.base09}";
        };
      };
    };
  };
}
