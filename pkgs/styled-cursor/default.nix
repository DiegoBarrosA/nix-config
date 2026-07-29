{
  stdenvNoCC,
  lib,
  librsvg,
  xcursorgen,
  body,
  outline,
  accent,
  themeName ? "styled-cursor",
}:

stdenvNoCC.mkDerivation {
  pname = "styled-cursor";
  version = "1";

  src = ./.;

  nativeBuildInputs = [
    librsvg
    xcursorgen
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    mkdir -p "$TMPDIR/svgs"
    for f in svgs/*.svg; do
      base=$(basename "$f")
      cp "$f" "$TMPDIR/svgs/$base"
      sed -i \
        -e 's|@BODY@|${body}|g' \
        -e 's|@OUTLINE@|${outline}|g' \
        -e 's|@ACCENT@|${accent}|g' \
        "$TMPDIR/svgs/$base"
    done
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    CURSORS="$out/share/icons/${themeName}/cursors"
    mkdir -p "$CURSORS"
    R="$TMPDIR/render"
    mkdir -p "$R"
    S="$TMPDIR/svgs"

    render_static() {
      local name="$1" svg="$2" xhot="$3" yhot="$4"
      local cfg="$R/$name.cursor"
      rm -f "$cfg"
      for size in 24 32 48 64; do
        rsvg-convert -w "$size" -h "$size" "$S/$svg" -o "$R/$name-$size.png"
        echo "$size $xhot $yhot $R/$name-$size.png" >> "$cfg"
      done
      xcursorgen "$cfg" "$CURSORS/$name"
    }

    render_wait() {
      local cfg="$R/wait.cursor"
      rm -f "$cfg"
      for frame in 0 1 2 3 4 5 6 7; do
        local rot=$((frame * 45))
        sed "s|@ROT@|$rot|g" "$S/wait-frame.svg" > "$R/wait-frame-$frame.svg"
        for size in 24 32 48 64; do
          rsvg-convert -w "$size" -h "$size" "$R/wait-frame-$frame.svg" \
            -o "$R/wait-$frame-$size.png"
          echo "$size 16 16 $R/wait-$frame-$size.png 60" >> "$cfg"
        done
      done
      xcursorgen "$cfg" "$CURSORS/wait"
    }

    render_static default     arrow.svg        4  4
    render_static pointer     hand.svg         13 5
    render_static text        text.svg         16 16
    render_wait
    render_static progress    progress.svg     4  4
    render_static crosshair   crosshair.svg    16 16
    render_static move        move.svg         16 16
    render_static ew-resize   resize-h.svg     16 16
    render_static ns-resize   resize-v.svg     16 16
    render_static nwse-resize resize-nwse.svg  16 16
    render_static nesw-resize resize-nesw.svg  16 16
    render_static not-allowed not-allowed.svg  16 16
    render_static grab        grab.svg         16 14
    render_static grabbing    grabbing.svg     16 14
    render_static zoom-in     zoom-in.svg      13 13
    render_static zoom-out    zoom-out.svg     13 13

    # X11 alias symlinks
    cd "$CURSORS"
    ln -s default left_ptr
    ln -s default arrow
    ln -s default top_left_arrow
    ln -s pointer hand2
    ln -s pointer pointing_hand
    ln -s text xterm
    ln -s text ibeam
    ln -s wait watch
    ln -s progress left_ptr_watch
    ln -s progress half-busy
    ln -s progress 08e8e1c95fe2fc01f976f1e063a24ccd
    ln -s crosshair cross
    ln -s crosshair diamond_cross
    ln -s move fleur
    ln -s move size_all
    ln -s ew-resize col-resize
    ln -s ew-resize sb_h_double_arrow
    ln -s ew-resize h_double_arrow
    ln -s ew-resize e-resize
    ln -s ew-resize w-resize
    ln -s ns-resize row-resize
    ln -s ns-resize sb_v_double_arrow
    ln -s ns-resize v_double_arrow
    ln -s ns-resize n-resize
    ln -s ns-resize s-resize
    ln -s nwse-resize bd_double_arrow
    ln -s nwse-resize bottom_right_corner
    ln -s nwse-resize top_left_corner
    ln -s nwse-resize nw-resize
    ln -s nwse-resize se-resize
    ln -s nesw-resize fd_double_arrow
    ln -s nesw-resize bottom_left_corner
    ln -s nesw-resize top_right_corner
    ln -s nesw-resize ne-resize
    ln -s nesw-resize sw-resize
    ln -s not-allowed forbidden
    ln -s not-allowed circle
    ln -s not-allowed crossed_circle
    ln -s grab openhand
    ln -s grab hand1
    ln -s grabbing closedhand
    ln -s grabbing dnd-move
    ln -s grabbing dnd-copy

    # index.theme
    mkdir -p "$out/share/icons/${themeName}"
    printf '[Icon Theme]\nName=${themeName}\n' \
      > "$out/share/icons/${themeName}/index.theme"

    runHook postInstall
  '';

  meta = {
    description = "SVG cursor theme recolored from base16 palette";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
