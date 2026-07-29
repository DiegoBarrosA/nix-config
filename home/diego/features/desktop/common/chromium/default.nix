{ pkgs, ... }:
{
  programs.brave = {
    enable = true;
    extensions = [
      # uBlock Origin
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
    ];
    # commandLineArgs removed: newer nixpkgs brave is built with mkDerivation
    # (no callPackage-style .override), so HM's override path fails. Flags are
    # passed via brave-flags.conf instead, which Brave reads natively on Linux.
  };

  # Wayland + VA-API flags via the native Linux flags file.
  # AMD 680M (VCN3): VA-API decode conflicts with wlr-screencopy DMA-BUF
  # during WebRTC screen share, freezing the stream after ~10 s.
  home.file.".config/brave/brave-flags.conf".text = ''
    --enable-features=UseOzonePlatform
    --ozone-platform=wayland
    --disable-features=VaapiVideoDecoder,VaapiVideoEncoder
  '';
}
