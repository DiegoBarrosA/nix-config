{ config, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = [ "emacsclient.desktop" ];
      "application/vnd.comicbook+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
      "application/zip" = [ "xarchiver.desktop" ];
    };
  };
}
