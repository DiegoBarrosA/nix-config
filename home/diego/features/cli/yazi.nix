{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    settings.icon.enable = false;
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
