{ pkgs, ... }:
{
  programs.brave = {
    enable = true;
    extensions = [
      # uBlock Origin
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
    ];
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      # AMD 680M (VCN3): VA-API decode conflicts with wlr-screencopy DMA-BUF
      # during WebRTC screen share, freezing the stream after ~10 s.
      # Same root cause as Firefox media.ffmpeg.vaapi.enabled = false.
      "--disable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    ];
  };
}
