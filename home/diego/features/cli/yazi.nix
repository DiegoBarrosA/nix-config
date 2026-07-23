{ pkgs, ... }:
let
  # Opens selected file(s) in the Helix pane when inside the dev Zellij layout.
  # Moves focus right to the editor pane, sends :open <file>, then returns.
  # Falls back to plain hx when not inside Zellij.
  hx-open = pkgs.writeShellScriptBin "hx-open" ''
    FILE=$(realpath "$1")
    if [ -n "''${ZELLIJ:-}" ]; then
      zellij action move-focus right
      sleep 0.05
      zellij action write-chars ":open $FILE"
      zellij action write 13
      zellij action move-focus left
    else
      hx "$FILE"
    fi
  '';
in
{
  home.packages = with pkgs; [ ueberzugpp hx-open ];

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    settings = {
      icon.enable = false;

      preview = {
        max_width = 1000;
        max_height = 1000;
        ueberzug_scale = 1;
      };
    };
    keymap.manager.prepend_keymap = [
      {
        on = [ "e" ];
        run = ''shell 'hx-open "$1"' --confirm'';
        desc = "Open in Helix (Zellij dev layout)";
      }
    ];
    theme = {
      status = {
        sep_left = { open = ""; close = ""; };
        sep_right = { open = ""; close = ""; };
      };
      icon = {
        globs = [ ];
        dirs = [ ];
        files = [ ];
        exts = [ ];
        conds = [ ];
      };
    };
  };

  # Custom desktop file so Yazi appears as a file manager for MIME association
  xdg.dataFile."applications/yazi-fm.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Yazi
      Exec=alacritty -e yazi
      Categories=FileManager;
      MimeType=inode/directory;
    '';
  };
}
