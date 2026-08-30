{ config, ... }:
let
  c = config.colorscheme.colors;
in {
  xdg.configFile."ardour9/my-grayscale-dark-ardour-9.7.colors".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <Ardour theme-name="grayscale-dark">
      <Colors>
        <!-- Alert / status colors (grayscale-tinted) -->
        <Color name="alert:blue" value="${c.base0D}ff"/>
        <Color name="alert:cyan" value="${c.base0C}ff"/>
        <Color name="alert:green" value="${c.base0B}ff"/>
        <Color name="alert:greenish" value="${c.base0B}ff"/>
        <Color name="alert:orange" value="${c.base09}ff"/>
        <Color name="alert:red" value="${c.base08}ff"/>
        <Color name="alert:ruddy" value="${c.base08}ff"/>
        <Color name="alert:yellow" value="${c.base0A}ff"/>

        <!-- Meter gradient -->
        <Color name="meter color0" value="008800ff"/>
        <Color name="meter color1" value="00aa00ff"/>
        <Color name="meter color2" value="00ff00ff"/>
        <Color name="meter color3" value="00ff00ff"/>
        <Color name="meter color4" value="fff000ff"/>
        <Color name="meter color5" value="fff000ff"/>
        <Color name="meter color6" value="ff8800ff"/>
        <Color name="meter color7" value="ff8800ff"/>
        <Color name="meter color8" value="ff0000ff"/>
        <Color name="meter color9" value="ff0000ff"/>

        <!-- MIDI meter -->
        <Color name="midi meter 52" value="e8faa1ff"/>
        <Color name="midi meter 53" value="f2c37dff"/>
        <Color name="midi meter 54" value="ffac44ff"/>
        <Color name="midi meter 55" value="f48352ff"/>
        <Color name="midi meter 56" value="f85813ff"/>

        <!-- Piano roll -->
        <Color name="pianoroll: insensitive bender line" value="96b2df84"/>
        <Color name="pianoroll: insensitive expression line" value="dfc59684"/>
        <Color name="pianoroll: insensitive modulation line" value="afdf9684"/>
        <Color name="pianoroll: insensitive pressure line" value="96dfc984"/>
        <Color name="pianoroll: user1 line" value="df96b084"/>
        <Color name="pianoroll: user2 line" value="bc96df84"/>
        <Color name="pianoroll: user3 line" value="9699df84"/>
        <Color name="pianoroll: velocity" value="ff9408ff"/>

        <!-- Theme core -->
        <Color name="theme:bg" value="${c.base01}ff"/>
        <Color name="theme:bg1" value="${c.base02}ff"/>
        <Color name="theme:bg2" value="${c.base00}ff"/>
        <Color name="theme:contrasting" value="${c.base07}ff"/>
        <Color name="theme:contrasting alt" value="${c.base0A}ff"/>
        <Color name="theme:contrasting clock" value="${c.base0B}ff"/>
        <Color name="theme:contrasting less" value="${c.base04}ff"/>
        <Color name="theme:contrasting selection" value="${c.base0D}ff"/>

        <!-- Neutral grayscale ramp (darkest to lightest) -->
        <Color name="neutral:background" value="${c.base01}ff"/>
        <Color name="neutral:background2" value="${c.base02}ff"/>
        <Color name="neutral:backgroundest" value="${c.base00}ff"/>
        <Color name="neutral:foreground" value="${c.base05}ff"/>
        <Color name="neutral:foreground2" value="${c.base06}ff"/>
        <Color name="neutral:foregroundest" value="${c.base07}ff"/>
        <Color name="neutral:midground" value="${c.base03}ff"/>

        <!-- Widget / buttons -->
        <Color name="widget:bg" value="${c.base02}ff"/>
        <Color name="widget:blue" value="${c.base0D}ff"/>
        <Color name="widget:blue darker" value="${c.base03}ff"/>
        <Color name="widget:blue lighter" value="${c.base04}ff"/>
        <Color name="widget:gray" value="${c.base03}ff"/>
        <Color name="widget:green" value="${c.base0B}ff"/>
        <Color name="widget:green darker" value="${c.base03}ff"/>
        <Color name="widget:orange" value="${c.base09}ff"/>
        <Color name="widget:ruddy" value="${c.base08}ff"/>
        <Color name="widget:yellow" value="${c.base0A}ff"/>
      </Colors>
      <ColorAliases>
        <!-- GTK integration -->
        <ColorAlias name="gtk_background" alias="theme:bg"/>
        <ColorAlias name="gtk_foreground" alias="neutral:foreground"/>
        <ColorAlias name="gtk_bases" alias="theme:bg2"/>
        <ColorAlias name="gtk_texts" alias="neutral:foreground"/>
        <ColorAlias name="gtk_mono" alias="neutral:foreground"/>
        <ColorAlias name="gtk_bg_selected" alias="theme:contrasting selection"/>
        <ColorAlias name="gtk_darkest" alias="theme:bg2"/>
        <ColorAlias name="gtk_lightest" alias="neutral:foregroundest"/>

        <!-- Playhead / transport -->
        <ColorAlias name="play head" alias="theme:contrasting"/>

        <!-- Waveform -->
        <ColorAlias name="waveform fill" alias="neutral:foregroundest"/>
        <ColorAlias name="waveform outline" alias="neutral:backgroundest"/>
        <ColorAlias name="selected waveform fill" alias="theme:contrasting selection"/>
        <ColorAlias name="clipped waveform" alias="alert:red"/>

        <!-- Selection / regions -->
        <ColorAlias name="selection rect" alias="theme:contrasting selection"/>
        <ColorAlias name="selected region base" alias="theme:contrasting selection"/>
        <ColorAlias name="recording rect" alias="alert:red"/>

        <!-- Grid / canvas -->
        <ColorAlias name="grid line" alias="neutral:midground"/>
        <ColorAlias name="canvas:background" alias="theme:bg2"/>

        <!-- MIDI -->
        <ColorAlias name="midi note selected" alias="theme:contrasting selection"/>
        <ColorAlias name="midi track base" alias="widget:blue"/>
        <ColorAlias name="piano roll black" alias="neutral:backgroundest"/>
        <ColorAlias name="piano roll white" alias="neutral:foregroundest"/>

        <!-- Clocks -->
        <ColorAlias name="clock:background" alias="theme:bg"/>
        <ColorAlias name="clock:cursor" alias="theme:contrasting"/>
        <ColorAlias name="clock:text" alias="neutral:foreground"/>
        <ColorAlias name="big clock:text" alias="neutral:foregroundest"/>

        <!-- Transport buttons -->
        <ColorAlias name="transport button: fill" alias="widget:bg"/>
        <ColorAlias name="transport button: fill active" alias="widget:blue"/>
        <ColorAlias name="transport button: led active" alias="alert:green"/>

        <!-- Processor / mixer -->
        <ColorAlias name="processor fader: fill" alias="widget:blue"/>
        <ColorAlias name="processor prefader: fill" alias="widget:green"/>
        <ColorAlias name="processor postfader: fill" alias="widget:orange"/>

        <!-- Meter -->
        <ColorAlias name="meter background top" alias="neutral:backgroundest"/>
        <ColorAlias name="meter background bottom" alias="neutral:background"/>
        <ColorAlias name="meter outline" alias="neutral:midground"/>
      </ColorAliases>
      <Modifiers>
        <Modifier name="audio bus base" modifier="= alpha:0.3"/>
        <Modifier name="audio track base" modifier="= alpha:0.3"/>
        <Modifier name="midi bus base" modifier="= alpha:0.3"/>
        <Modifier name="midi track base" modifier="= alpha:0.3"/>
        <Modifier name="region alpha" modifier="= alpha:0.75"/>
        <Modifier name="region summary" modifier="= alpha:0.5"/>
        <Modifier name="selection rect" modifier="= alpha:0.15"/>
        <Modifier name="recording rect" modifier="= alpha:0.25"/>
        <Modifier name="midi note" modifier="= alpha:0.8"/>
        <Modifier name="midi note selected" modifier="= alpha:0.9"/>
        <Modifier name="grid line" modifier="= alpha:0.8"/>
        <Modifier name="video track base" modifier="= alpha:0.3"/>
      </Modifiers>
    </Ardour>
  '';
}
