{ pkgs, lib, inputs, ... }:
let

  ardour-scaled = pkgs.writeShellScriptBin "ardour9" ''
    export GDK_SCALE=2
    export GDK_DPI_SCALE=0.5
    export GTK2_THEME=ardour-flat
    exec ${pkgs.ardour}/bin/ardour9 "$@"
  '';
in
{
  imports = [
    ./ardour-theme.nix
    ./ardour-gtk2-theme.nix
    ./reaper-theme.nix
  ];

  home.file.".local/share/vitalium/VitalPresets".source = inputs.vital-presets;

  home.packages = [

    ardour-scaled
  ]
  ++ (with pkgs; [

    carla
    qpwgraph
    xjadeo
    reaper

    surge-xt
    helm
    dexed
    zynaddsubfx
    yoshimi
    cardinal
    odin2
    setbfree
    distrho-ports
    redux

    lsp-plugins
    calf
    dragonfly-reverb
    airwindows
    zam-plugins
    gxplugins-lv2

    geonkick
    x42-avldrums
    sfizz
  ]);
}
