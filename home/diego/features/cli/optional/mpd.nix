{ config, ... }: {
  services.mpd = {
    #    enable = true;
    extraConfig = ''
        audio_output {
         type "pipewire"
         name "My PipeWire Output"
       }
        audio_output {
            type            "fifo"
             name            "Visualizer feed"
              path            "/tmp/mpd.fifo"
             format          "44100:16:2"
      }
    '';
    musicDirectory = "${config.xdg.userDirs.music}";
  };
}
