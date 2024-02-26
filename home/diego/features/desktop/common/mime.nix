{ config, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = [ "imv-folder.desktop" ];

      "image/png" = [ "imv-folder.desktop" ];
      "text/plain" = [ "emacsclient.desktop" ];
      "application/vnd.comicbook+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
      "application/zip" = [ "xarchiver.desktop" ];
    };
  };
}
