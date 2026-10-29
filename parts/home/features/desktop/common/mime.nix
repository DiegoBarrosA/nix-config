{ ... }:
{
  flake.modules.homeManager.desktop-common-mime =
{ config, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {

      "text/html" = [ "zen-beta.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
      "x-scheme-handler/about" = [ "zen-beta.desktop" ];
      "x-scheme-handler/unknown" = [ "zen-beta.desktop" ];
      "application/xhtml+xml" = [ "zen-beta.desktop" ];
      "application/x-extension-htm" = [ "zen-beta.desktop" ];
      "application/x-extension-html" = [ "zen-beta.desktop" ];
      "application/x-extension-shtml" = [ "zen-beta.desktop" ];
      "application/x-extension-xhtml" = [ "zen-beta.desktop" ];
      "application/x-extension-xht" = [ "zen-beta.desktop" ];

      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

      "application/zip" = [ "xarchiver.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];

    };
  };
};
}
