{ ... }:
{
  flake.modules.homeManager.desktop-common-mime =
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

      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      "application/zip" = [ "xarchiver.desktop" ];
      "application/pdf" = [ "org.kde.okular.desktop" ];

    };
  };
};
}
