{ config, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {

      "text/html" = [ "firefox-esr.desktop" ];
      "x-scheme-handler/http" = [ "firefox-esr.desktop" ];
      "x-scheme-handler/https" = [ "firefox-esr.desktop" ];
      "x-scheme-handler/about" = [ "firefox-esr.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox-esr.desktop" ];
      "application/xhtml+xml" = [ "firefox-esr.desktop" ];
      "application/x-extension-htm" = [ "firefox-esr.desktop" ];
      "application/x-extension-html" = [ "firefox-esr.desktop" ];
      "application/x-extension-shtml" = [ "firefox-esr.desktop" ];
      "application/x-extension-xhtml" = [ "firefox-esr.desktop" ];
      "application/x-extension-xht" = [ "firefox-esr.desktop" ];

      "text/plain" = [ "emacsclient.desktop" ];
      "application/vnd.comicbook+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura-cb.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];

      "inode/directory" = [ "yazi-fm.desktop" ];

      "application/zip" = [ "xarchiver.desktop" ];

    };
  };
}
