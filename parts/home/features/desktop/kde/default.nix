{ ... }:
{
  flake.modules.homeManager.desktop-kde =
    { config, lib, pkgs, ... }:
    let
      home = config.home.homeDirectory;

      # Dolphin side bar. Hardcoded, so Dolphin cannot edit it (the file is a
      # read-only store symlink).
      places = [
        { title = "Home"; href = "file://${home}"; icon = "user-home"; }
        { title = "Documents"; href = "file://${home}/Documents"; icon = "folder-documents"; }
        { title = "Downloads"; href = "file://${home}/Downloads"; icon = "folder-download"; }
        { title = "Pictures"; href = "file://${home}/Pictures"; icon = "folder-pictures"; }
        { title = "Projects"; href = "file://${home}/Projects"; icon = "folder-development"; }
        { title = "Cobalto media"; href = "smb://cobalto/media"; icon = "folder-remote"; }
        { title = "Cobalto storage"; href = "smb://cobalto/storage"; icon = "folder-remote"; }
      ];

      bookmark = i: p: ''
        <bookmark href="${p.href}">
         <title>${p.title}</title>
         <info>
          <metadata owner="http://freedesktop.org">
           <bookmark:icon name="${p.icon}"/>
          </metadata>
          <metadata owner="http://www.kde.org">
           <ID>declarative-${toString i}</ID>
           <isSystemItem>false</isSystemItem>
          </metadata>
         </info>
        </bookmark>
      '';

      userPlaces = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE xbel>
        <xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
         <info>
          <metadata owner="http://www.kde.org">
           <kde_places_version>4</kde_places_version>
          </metadata>
         </info>
        ${lib.concatStrings (lib.imap0 bookmark places)}</xbel>
      '';
    in
    {
      home.sessionVariables.TERMINAL = "konsole";

      home.packages = [ pkgs.wl-clipboard ];

      programs.plasma = {
        enable = true;
        # Only the keys set here are managed. Set overrideConfig = true to reset
        # everything else to the defaults on login (it deletes the KDE config files).
        input.keyboard.options = [ "ctrl:nocaps" ];
        configFile.kwinrc.MouseBindings = {
          # Super+left drag moves, Super+right drag resizes.
          CommandAllKey = "Meta";
          CommandAll1 = "Move";
          CommandAll3 = "Resize";
        };
      };

      programs.konsole = {
        enable = true;
        defaultProfile = "default";
        profiles.default = {
          command = "${pkgs.nushell}/bin/nu --login";
          font = {
            name = config.stylix.fonts.monospace.name;
            size = 12;
          };
        };
      };

      xdg.dataFile."user-places.xbel" = {
        text = userPlaces;
        force = true;
      };
    };
}
