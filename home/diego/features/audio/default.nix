{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let

  mixbus-scaled = pkgs.writeShellScriptBin "mixbus12" ''
    export GDK_SCALE=2
    export GDK_DPI_SCALE=0.5
    exec ${pkgs.mixbus}/bin/mixbus12 "$@"
  '';

  wine = pkgs.wineWow64Packages.stable;

  nixProfile = "${config.home.homeDirectory}/.nix-profile";

  winePrefix = "${config.home.homeDirectory}/.wine";
  wineasioDll = "${pkgs.wineasio}/lib/wine/x86_64-windows/wineasio64.dll";
  wineasioUnix = "${pkgs.wineasio}/lib/wine/x86_64-unix/wineasio64.dll.so";

  linkPlugins = ''
    link_plugins() {
      local src="$1" dst="$2" base
      mkdir -p "$dst"
      find "$dst" -maxdepth 1 -type l -exec rm -f {} +
      if [ -d "$src" ]; then
        for f in "$src"/*; do
          [ -e "$f" ] && { base=$(basename "$f"); ln -sfn "$f" "$dst/$base"; }
        done
      fi
    }
    link_plugins "${nixProfile}/lib/vst"  "$HOME/.vst"
    link_plugins "${nixProfile}/lib/vst3" "$HOME/.vst3"
    link_plugins "${nixProfile}/lib/clap" "$HOME/.clap"
    link_plugins "${nixProfile}/lib/lv2"  "$HOME/.lv2"
  '';
in
{
  imports = [
    ./mixbus-font.nix
  ];

  home.file.".local/share/vitalium/VitalPresets".source = inputs.vital-presets;

  home.packages = [

    mixbus-scaled
  ]
  ++ (with pkgs; [

    carla
    qpwgraph
    xjadeo

    yabridge
    yabridgectl

    wine
    wineasio

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

  home.activation.pluginLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] linkPlugins;

  home.activation.wineasioJack = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WINEPREFIX_DIR="${winePrefix}"
    WINE="${wine}/bin/wine"
    WINEBOOT="${wine}/bin/wineboot"
    WINESERVER="${wine}/bin/wineserver"
    SYS32="$WINEPREFIX_DIR/drive_c/windows/system32"

    if [ ! -d "$WINEPREFIX_DIR" ]; then
      mkdir -p "$WINEPREFIX_DIR"
      WINEDLLOVERRIDES="mscoree,mshtml=" \
        WINEARCH=win64 WINEPREFIX="$WINEPREFIX_DIR" "$WINEBOOT" -u
    fi

    if [ ! -f "$SYS32/wineasio64.dll" ] || ! cmp -s "${wineasioDll}" "$SYS32/wineasio64.dll"; then
      mkdir -p "$SYS32"
      cp -f "${wineasioDll}" "$SYS32/wineasio64.dll"

      # Register via the unix sidecar path, mirroring the upstream
      # wineasio-register script.
      WINEPREFIX="$WINEPREFIX_DIR" "$WINE" regsvr32 "${wineasioUnix}" || true
      "$WINESERVER" -w 2>/dev/null || true
    fi
  '';
}
