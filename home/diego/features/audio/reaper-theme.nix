{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.colorscheme.colors;
  scheme = config.colorscheme.type;
  baseSize = fonts.sizes.terminal;
  inherit (config.stylix) fonts;

  themeZip = ../../../../assets/audio/reaper/reapetips-theme-v1.93b.zip;
  innerTheme = "ReaperTips_v1.93b.ReaperTheme";
  innerDir = "ReaperTips_v1.93b";

  hexDigit = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
    "A" = 10;
    "B" = 11;
    "C" = 12;
    "D" = 13;
    "E" = 14;
    "F" = 15;
  };
  hexToDec =
    str:
    let
      len = builtins.stringLength str;
      step =
        i: acc: if i >= len then acc else step (i + 1) (acc * 16 + hexDigit.${builtins.substring i 1 str});
    in
    step 0 0;

  reaperInt =
    hex:
    let
      h = if builtins.substring 0 1 hex == "#" then builtins.substring 1 6 hex else hex;
    in
    hexToDec (builtins.substring 0 2 h)
    + hexToDec (builtins.substring 2 2 h) * 256
    + hexToDec (builtins.substring 4 2 h) * 65536;

  slotValues = {
    base00 = [
      0
      144128
      147456
      163840
      166912
      196608
      723723
      855309
    ];
    base01 = [
      10240
      140800
      986895
      1052688
      1315344
      1315860
      1447446
      1776411
      1842204
      1907997
      1973790
      2039583
      2105376
      2171169
      2236962
    ];
    base02 = [
      2105408
      2171199
      2434341
      2500134
      2565927
      2631720
      2697513
      2763306
      2894892
      2960685
      3026478
      3158064
    ];
    base03 = [
      (-2144193998)
      2113568
      3223857
      3289650
      3355443
      3487029
      3552822
      3684408
      3881787
      3947580
      4079166
      4210752
      4342338
      4670000
    ];
    base04 = [
      (-2142878138)
      4539717
      4605510
      4737096
      5000268
      5066061
      5066085
      5197647
      5263440
      5395026
      5789784
      6052956
      6381921
      6579300
      6645093
      6710886
      6904647
    ];
    base05 = [
      (-2138930558)
      7241856
      8092539
      8289918
      8421248
      8421504
      8816262
      9012099
      9211020
    ];
    base06 = [
      9474192
      9737364
      10000536
      10066329
      10132122
      10395294
      10526880
      10855845
      10921638
      11842740
      12237498
    ];
    base07 = [
      12369084
      12632256
      13092807
      13158600
      13355979
      13421772
      13551298
      14079702
      14088447
      14211288
      14277081
      14745599
      15066597
      15132390
      15263976
      15395562
      15592941
      15724527
      15790320
      15921906
      16777215
    ];
    base08 = [
      64
      128
      192
      255
      12543
      45568
      65599
      1573013
      1709763
      3816092
      3947682
      4009983
      4210816
      4210943
      4530687
      4605695
      4868077
      5131263
      5649919
      6643428
      8421631
      8541951
    ];
    base09 = [
      32960
      1791487
      2119935
      3644415
      3704549
      3899040
      4033535
      4748287
      5077759
    ];
    base0A = [
      16448
      32896
      49280
      49344
      49407
      54525
      59904
      65535
      109945
      156290
      176896
      3201279
      3462908
      3654911
      3850750
      4047092
      4438501
      5636036
      6803454
      10808831
    ];
    base0B = [
      16384
      32768
      49152
      65280
      65312
      4113687
      6328416
      6547494
      8437600
      8437632
      8453889
      8453920
      8453952
      8453984
      10551136
      10551168
      12910532
    ];
    base0C = [
      4210688
      8421152
      8421184
      8421376
      8421440
      8437760
      9227588
      9699072
      10534784
      11722811
      12615680
      12632064
      12648224
      12648256
      12648320
      14145280
      14671663
      14745376
      14745472
      15115008
      16762368
      16776960
      16776961
      16777088
    ];
    base0D = [
      4194304
      147460
      4259648
      8388608
      8388609
      8404768
      8404800
      9529171
      12477994
      12582912
      12615552
      12615808
      14569774
      14680064
      14712704
      16293651
      16622099
      16693574
      16711680
      16761024
    ];
    base0E = [
      4194368
      7929977
      8388736
      8404864
      12540648
      12583040
      12599168
      13697279
      14696320
      16711808
      16747184
    ];
  };

  valueToSlot = lib.mergeAttrsList (
    lib.mapAttrsToList (
      slot: vals: lib.listToAttrs (map (v: lib.nameValuePair (toString v) slot) vals)
    ) slotValues
  );

  recolor =
    orig:
    let
      slot = valueToSlot.${toString orig} or null;
      u = if orig < 0 then orig + 4294967296 else orig;
    in
    if slot == null then
      orig
    else
      let
        alpha = lib.mod (u / 16777216) 256;
      in
      alpha * 16777216 + reaperInt c.${slot};

  pyMap = lib.concatMapStringsSep "\n" (v: "  ${toString v}: ${toString (recolor v)},") (
    lib.concatMap (slot: slotValues.${slot}) (builtins.attrNames slotValues)
  );

  recolorPy = pkgs.writeText "reaper-recolor.py" ''
    import re, sys

    work, scheme = sys.argv[1], sys.argv[2]

    MAP = {
    ${pyMap}
    }

    SKIP = re.compile(
        r"(drawmode|_mode$|_fillmode|_outlinemode|flags|_dbs|_scale|_dbscale|"
        r"_reason|_num|_gap|_docks|_selmode|_forced|_data)$")

    COL = re.compile(r"^(col_|tcp_|mcp_|arr|midi|track|mixer|genlist|mediaitem|"
                     r"vken|group_|acms|item_|fader|vu|llist|docker|checkbox|scrollbar)")

    def is_color_key(k):
        if SKIP.search(k):
            return False
        if k in ("autogroup",):
            return False
        return bool(COL.match(k))

    src = "%s/${innerTheme}" % (work,)
    out = []
    for raw in open(src).read().splitlines():
        line = raw.strip()
        if not line or line.startswith("[") or "=" not in line:
            out.append(raw)
            continue
        k, v = line.split("=", 1)
        try:
            num = int(v)
        except ValueError:
            out.append(raw)
            continue
        if is_color_key(k) and num in MAP:
            out.append("%s=%s" % (k, MAP[num]))
        else:
            out.append(raw)
    dst = "%s/%s.ReaperTheme" % (work, scheme)
    open(dst, "w").write("\n".join(out) + "\n")
    print("wrote %s" % dst)
  '';

  recoloredTheme = pkgs.runCommand "reapetips-${scheme}" { } ''
    mkdir -p "$TMPDIR/src" "$TMPDIR/work" "$out"
    ${pkgs.unzip}/bin/unzip -q ${themeZip} "Reapertips Theme v1.93b/02_Theme/Reapertips Theme.ReaperThemeZip" -d "$TMPDIR/src"
    ${pkgs.unzip}/bin/unzip -q "$TMPDIR/src/Reapertips Theme v1.93b/02_Theme/Reapertips Theme.ReaperThemeZip" -d "$TMPDIR/work"
    ${pkgs.python3}/bin/python3 ${recolorPy} "$TMPDIR/work" ${scheme}
    (cd "$TMPDIR/work" && ${pkgs.zip}/bin/zip -q -r "$TMPDIR/work/${scheme}.ReaperThemeZip" "${innerDir}" "${scheme}.ReaperTheme")
    cp "$TMPDIR/work/${scheme}.ReaperThemeZip" "$out/"
    cp "$TMPDIR/work/${scheme}.ReaperTheme" "$out/"
  '';

  reapetips-fonts = pkgs.runCommand "reapetips-fonts" { } ''
    mkdir -p "$out/share/fonts/truetype/reapetips"
    mkdir -p "$TMPDIR/fonts"
    ${pkgs.unzip}/bin/unzip -q ${themeZip} "Reapertips Theme v1.93b/01_Install these fonts/*.ttf" -d "$TMPDIR/fonts"
    cp "$TMPDIR"/fonts/Reapertips\ Theme\ v1.93b/01_Install\ these\ fonts/*.ttf "$out/share/fonts/truetype/reapetips/"
  '';

  reaperIni = "${config.home.homeDirectory}/.config/REAPER/reaper.ini";
  themeRef = "ColorThemes/${scheme}.ReaperThemeZip";

  nixProfile = "${config.home.homeDirectory}/.nix-profile";
  reduxBundle = "${nixProfile}/lib/vst2/RenoiseRedux.vst2/renoise_redux.vst3";
in
{
  home.packages = [
    reapetips-fonts
  ];

  xdg.configFile."REAPER/ColorThemes/${scheme}.ReaperThemeZip".source =
    "${recoloredTheme}/${scheme}.ReaperThemeZip";

  xdg.configFile."REAPER/libSwell-user.colortheme".text = ''
    default_font_face ${fonts.sansSerif.name}
    default_font_size ${toString baseSize}
    menubar_height 36
    menubar_font_size ${toString baseSize}
    menubar_spacing_width 8
    menubar_margin_width 6
    scrollbar_width 14
    scrollbar_min_thumb_height 4
    combo_height 28
    _3dface #${c.base01}
    _3dshadow #${c.base01}
    _3dhilight #${c.base01}
    _3ddkshadow #${c.base01}
    button_bg #${c.base01}
    button_text #${c.base06}
    button_text_disabled #${c.base04}
    button_shadow #${c.base01}
    button_hilight #${c.base01}
    checkbox_text #${c.base06}
    checkbox_text_disabled #${c.base04}
    checkbox_fg #${c.base07}
    checkbox_inter #${c.base0D}
    checkbox_bg #${c.base01}
    scrollbar #${c.base03}
    scrollbar_fg #${c.base05}
    scrollbar_bg #${c.base01}
    edit_cursor #${c.base07}
    edit_bg #${c.base01}
    edit_bg_disabled #${c.base01}
    edit_text #${c.base06}
    edit_text_disabled #${c.base04}
    edit_bg_sel #${c.base0D}
    edit_text_sel #${c.base00}
    edit_hilight #${c.base01}
    edit_shadow #${c.base01}
    info_bk #${c.base00}
    info_text #${c.base06}
    menu_bg #${c.base00}
    menu_shadow #${c.base00}
    menu_hilight #${c.base02}
    menu_text #${c.base06}
    menu_text_disabled #${c.base04}
    menu_bg_sel #${c.base0D}
    menu_text_sel #${c.base00}
    menu_scroll #${c.base03}
    menu_scroll_arrow #${c.base05}
    menu_submenu_arrow #${c.base05}
    menubar_bg #${c.base00}
    menubar_text #${c.base05}
    menubar_text_disabled #${c.base04}
    menubar_bg_sel #${c.base0D}
    menubar_text_sel #${c.base00}
    trackbar_track #${c.base01}
    trackbar_mark #${c.base01}
    trackbar_knob #${c.base0D}
    progress #${c.base0D}
    label_text #${c.base06}
    label_text_disabled #${c.base04}
    combo_text #${c.base06}
    combo_text_disabled #${c.base04}
    combo_bg #${c.base01}
    combo_bg2 #${c.base01}
    combo_shadow #${c.base01}
    combo_hilight #${c.base01}
    combo_arrow #${c.base06}
    combo_arrow_press #${c.base0D}
    listview_bg #${c.base00}
    listview_bg_sel #${c.base0D}
    listview_text #${c.base06}
    listview_text_sel #${c.base00}
    listview_bg_sel_inactive #${c.base04}
    listview_text_sel_inactive #${c.base06}
    listview_grid #${c.base00}
    listview_hdr_arrow #${c.base05}
    listview_hdr_shadow #${c.base00}
    listview_hdr_hilight #${c.base00}
    listview_hdr_bg #${c.base00}
    listview_hdr_text #${c.base06}
    treeview_text #${c.base06}
    treeview_bg #${c.base00}
    treeview_bg_sel #${c.base0D}
    treeview_text_sel #${c.base00}
    treeview_bg_sel_inactive #${c.base04}
    treeview_text_sel_inactive #${c.base06}
    treeview_arrow #${c.base06}
    tab_shadow #${c.base00}
    tab_hilight #${c.base01}
    tab_text #${c.base05}
    focusrect #${c.base07}
    group_text #${c.base06}
    group_shadow #${c.base00}
    group_hilight #${c.base02}
    focus_hilight #${c.base0D}
  '';

  home.activation.reaperTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set_ini_key() {
      local key="$1" val="$2"
      if ${pkgs.gnugrep}/bin/grep -q "^$key=" "${reaperIni}"; then
        ${pkgs.gnused}/bin/sed -i "s|^$key=.*|$key=$val|" "${reaperIni}"
      elif ${pkgs.gnugrep}/bin/grep -q '^\[REAPER\]' "${reaperIni}"; then
        ${pkgs.gnused}/bin/sed -i "s|^\[REAPER\]|[REAPER]\n$key=$val|" "${reaperIni}"
      else
        printf '[REAPER]\n%s=%s\n' "$key" "$val" >> "${reaperIni}"
      fi
    }
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
    link_plugins "${nixProfile}/lib/vst2/RenoiseRedux.vst2" "$HOME/.vst3"
    if [ -f "${reaperIni}" ]; then
      set_ini_key theme '${themeRef}'
    fi
  '';
}
