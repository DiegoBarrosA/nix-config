{ config, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {

      "text/html" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/http" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/https" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/about" = [ "firefox-devedition.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox-devedition.desktop" ];
      "application/xhtml+xml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-htm" = [ "firefox-devedition.desktop" ];
      "application/x-extension-html" = [ "firefox-devedition.desktop" ];
      "application/x-extension-shtml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-xhtml" = [ "firefox-devedition.desktop" ];
      "application/x-extension-xht" = [ "firefox-devedition.desktop" ];

      "text/plain" = [ "emacsclient.desktop" ];
      "application/vnd.comicbook+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];

      "inode/directory" = [ "yazi-fm.desktop" ];

      "application/zip" = [ "xarchiver.desktop" ];

    };
  };
}
