{
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9,11 card_label=a7III,a8III
  '';
  programs.droidcam.enable = true;
}
