{ pkgs, lib, ... }:

let
  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };
in
{
  # Required for PipeWire screen sharing on Wayland — without this flag,
  # Firefox falls back to XWayland, which can't use the xdg-desktop-portal-wlr
  # ScreenCast portal and throws NotAllowedError on getDisplayMedia().
  home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxAccounts = true;
      DisablePocket = true;

      ExtensionSettings = builtins.listToAttrs [
        (extension "ublock-origin" "uBlock0@raymondhill.net")
      ];

      SearchEngines = {
        Default = "ddg";
        Add = [
          {
            Name = "nixpkgs packages";
            URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
            IconURL = "https://wiki.nixos.org/favicon.ico";
            Alias = "@np";
          }
          {
            Name = "NixOS options";
            URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
            IconURL = "https://wiki.nixos.org/favicon.ico";
            Alias = "@no";
          }
          {
            Name = "NixOS Wiki";
            URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
            IconURL = "https://wiki.nixos.org/favicon.ico";
            Alias = "@nw";
          }
          {
            Name = "noogle";
            URLTemplate = "https://noogle.dev/q?term={searchTerms}";
            IconURL = "https://noogle.dev/favicon.ico";
            Alias = "@ng";
          }
        ];
      };
    };
  };

  # Define profile explicitly with a fixed path (reproducible, no random hash prefix)
  programs.firefox.profiles.dev-edition-default = {
    id = 0;
    isDefault = true;
    path = "dev-edition-default";
    extensions.force = true;

    # WebRTC outbound video bitrate bounds (kbps). Firefox ships max_bitrate=1000,
    # which caps *total* WebRTC video at 1 Mbps. Google Meet screen sharing uses
    # 3-layer VP8 simulcast (180p/360p/720p); at a 1 Mbps ceiling the allocator
    # only funds the two small layers and the 720p top layer encodes 0 frames, so
    # attendees viewing the presentation full-size see a frozen image (confirmed
    # via about:webrtc: outbound-rtp `f` layer stuck at framesEncoded=0). Raising
    # the ceiling lets the top layer be funded; raising start/min speeds the ramp
    # so it doesn't crawl up from the default 220 kbps. Defaults were 100/220/1000.
    settings = {
      "media.peerconnection.video.min_bitrate" = 512;
      "media.peerconnection.video.start_bitrate" = 1500;
      "media.peerconnection.video.max_bitrate" = 8000;

      # AMD 680M (VCN3 / RDNA 2): AV1 VA-API decode triggers a VCN ring timeout
      # (~10 s, the kernel GPU hang-check interval) during WebRTC sessions, freezing
      # the screen share. Firefox has no VA-API hardware encoder on Linux — only the
      # decoder is affected. Disabling AV1 keeps H.264/VP9 hardware-accelerated
      # while preventing the VCN crash (Mesa bug #5500). dmabuf enables zero-copy
      # DMA-BUF frame delivery on Wayland.
      "media.av1.enabled" = false;
      "widget.dmabuf.force-enabled" = true;
    };
  };

  stylix.targets.firefox = {
    enable = true;
    profileNames = [ "dev-edition-default" ];
    colorTheme.enable = true;
  };
}
