{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.colorscheme) colors;

  themeQml = ''
    pragma Singleton
    import QtQuick

    QtObject {
        readonly property color base00: "#${colors.base00}"
        readonly property color base01: "#${colors.base01}"
        readonly property color base02: "#${colors.base02}"
        readonly property color base03: "#${colors.base03}"
        readonly property color base04: "#${colors.base04}"
        readonly property color base05: "#${colors.base05}"
        readonly property color base06: "#${colors.base06}"
        readonly property color base07: "#${colors.base07}"
        readonly property color base08: "#${colors.base08}"
        readonly property color base09: "#${colors.base09}"
        readonly property color base0A: "#${colors.base0A}"
        readonly property color base0B: "#${colors.base0B}"
        readonly property color base0C: "#${colors.base0C}"
        readonly property color base0D: "#${colors.base0D}"
        readonly property color base0E: "#${colors.base0E}"
        readonly property color base0F: "#${colors.base0F}"
        readonly property string font: "Jost"
    }
  '';
in
{
  home.packages = [
    pkgs.quickshell
    pkgs.jq
    pkgs.wireplumber
  ];

  xdg.configFile."quickshell/shell.qml".source = ./shell.qml;
  xdg.configFile."quickshell/qmldir".source = ./qmldir;
  xdg.configFile."quickshell/Theme.qml".text = themeQml;
}
