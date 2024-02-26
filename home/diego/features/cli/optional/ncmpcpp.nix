{
  programs.ncmpcpp = {
    enable = true;
    settings = {
      visualizer_output_name = "my_fifo";
      visualizer_look = "▐●";
      visualizer_in_stereo = "yes";
      visualizer_data_source = "/tmp/mpd.fifo";
    };
  };
}
