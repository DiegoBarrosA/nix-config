{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

let
  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  # Cascade reads its palette from a small set of CSS variables at the top of
  # cascade-colours.css; everything else in that file derives from these. We
  # override just those variables, wired to the Stylix/nix-colors base16
  # palette so Firefox matches the rest of the system theme.
  c = config.colorscheme.colors;
  cascadeColours = ''
    /*---+---+---+---+---+---+---+
     | C | O | L | O | U | R | S |  (nix-managed override, wired to base16)
     +---+---+---+---+---+---+---*/

    :root {
      /* Container Tabs plugin identity colours (base16 accents) */
      --uc-identity-colour-blue: #${c.base0D};
      --uc-identity-colour-turquoise: #${c.base0C};
      --uc-identity-colour-green: #${c.base0B};
      --uc-identity-colour-yellow: #${c.base0A};
      --uc-identity-colour-orange: #${c.base09};
      --uc-identity-colour-red: #${c.base08};
      --uc-identity-colour-pink: #${c.base0F};
      --uc-identity-colour-purple: #${c.base0E};

      /* Cascade's main colour scheme */
      --uc-base-colour: #${c.base01};      /* main background */
      --uc-highlight-colour: #${c.base02}; /* secondary background */
      --uc-inverted-colour: #${c.base05};  /* primary text */
      --uc-muted-colour: #${c.base04};     /* muted text */
      --uc-accent-colour: var(--uc-identity-colour-blue);
    }

    /* --- Below: verbatim reassignments from upstream cascade-colours.css.
       These map the variables above onto Firefox internals. --- */
    :root {
      --lwt-frame: var(--uc-base-colour) !important;
      --lwt-accent-color: var(--lwt-frame) !important;
      --lwt-text-color: var(--uc-inverted-colour) !important;

      --toolbar-field-color: var(--uc-inverted-colour) !important;

      --toolbar-field-focus-color: var(--uc-inverted-colour) !important;
      --toolbar-field-focus-background-color: var(--uc-highlight-colour) !important;
      --toolbar-field-focus-border-color: transparent !important;

      --toolbar-field-background-color: var(--lwt-frame) !important;
      --lwt-toolbar-field-highlight: var(--uc-inverted-colour) !important;
      --lwt-toolbar-field-highlight-text: var(--uc-highlight-colour) !important;
      --urlbar-popup-url-color: var(--uc-accent-colour) !important;

      --lwt-tab-text: var(--lwt-text-colour) !important;

      --lwt-selected-tab-background-color: var(--uc-highlight-colour) !important;

      --toolbar-bgcolor: var(--lwt-frame) !important;
      --toolbar-color: var(--lwt-text-color) !important;
      --toolbarseparator-color: var(--uc-accent-colour) !important;
      --toolbarbutton-hover-background: var(--uc-highlight-colour) !important;
      --toolbarbutton-active-background: var(--toolbarbutton-hover-background) !important;

      --lwt-sidebar-background-color: var(--lwt-frame) !important;
      --sidebar-background-color: var(--lwt-sidebar-background-color) !important;

      --urlbar-box-bgcolor: var(--uc-highlight-colour) !important;
      --urlbar-box-text-color: var(--uc-muted-colour) !important;
      --urlbar-box-hover-bgcolor: var(--uc-highlight-colour) !important;
      --urlbar-box-hover-text-color: var(--uc-inverted-colour) !important;
      --urlbar-box-focus-bgcolor: var(--uc-highlight-colour) !important;
    }

    .identity-color-blue { --identity-tab-color: var(--uc-identity-colour-blue) !important; --identity-icon-color: var(--uc-identity-colour-blue) !important; }
    .identity-color-turquoise { --identity-tab-color: var(--uc-identity-colour-turquoise) !important; --identity-icon-color: var(--uc-identity-colour-turquoise) !important; }
    .identity-color-green { --identity-tab-color: var(--uc-identity-colour-green) !important; --identity-icon-color: var(--uc-identity-colour-green) !important; }
    .identity-color-yellow { --identity-tab-color: var(--uc-identity-colour-yellow) !important; --identity-icon-color: var(--uc-identity-colour-yellow) !important; }
    .identity-color-orange { --identity-tab-color: var(--uc-identity-colour-orange) !important; --identity-icon-color: var(--uc-identity-colour-orange) !important; }
    .identity-color-red { --identity-tab-color: var(--uc-identity-colour-red) !important; --identity-icon-color: var(--uc-identity-colour-red) !important; }
    .identity-color-pink { --identity-tab-color: var(--uc-identity-colour-pink) !important; --identity-icon-color: var(--uc-identity-colour-pink) !important; }
    .identity-color-purple { --identity-tab-color: var(--uc-identity-colour-purple) !important; --identity-icon-color: var(--uc-identity-colour-purple) !important; }
  '';
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
      "browser.startup.homepage" = "https://home.minerales.network/";
      "browser.startup.page" = 1;
      "browser.newtabpage.url" = "https://home.minerales.network/";

      "media.peerconnection.video.min_bitrate" = 512;
      "media.peerconnection.video.start_bitrate" = 1500;
      "media.peerconnection.video.max_bitrate" = 8000;

      # AMD 680M (VCN3 / RDNA 2): VA-API decode (incoming video from participants)
      # conflicts with wlr-screencopy (outgoing screen capture) via DMA-BUF resource
      # contention, freezing the share after ~10 s. Disabling the FFmpeg VA-API path
      # removes the conflict; video playback uses a separate decode path unaffected.
      # Same root cause affects Brave — see hosts/rubi/default.nix for system fix.
      "media.ffmpeg.vaapi.enabled" = false;

      # Cascade theme requirements:
      # userChrome.css must be enabled for custom chrome to load, and
      # svg.context-properties lets Cascade's icons inherit theme colors.
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      "svg.context-properties.content.enabled" = true;
      # Cascade is keyboard-centered; density/UX prefs it recommends.
      "browser.compactmode.show" = true;
      "browser.uidensity" = 1;
    };
  };

  stylix.targets.firefox = {
    enable = true;
    profileNames = [ "dev-edition-default" ];
    colorTheme.enable = true;
  };

  # Cascade: minimalistic, keyboard-centered userChrome theme.
  #
  # We can't symlink the whole chrome/ dir and also override one file inside
  # it (a dir symlink is opaque). Instead we symlink chrome/userChrome.css and
  # every file in chrome/includes/ individually, EXCEPT cascade-colours.css,
  # which we replace with the nix-generated palette override (cascadeColours)
  # wired to the Stylix base16 scheme.
  #
  # Required about:config prefs are set in the profile settings above.
  home.file =
    let
      profileChrome = ".config/mozilla/firefox/dev-edition-default/chrome";
      includesDir = "${inputs.cascade}/chrome/includes";
      # Every filename in upstream chrome/includes/
      includeNames = builtins.attrNames (builtins.readDir includesDir);
      # Symlink each include except the colours file (we override that one)
      includeLinks = builtins.listToAttrs (
        map (name: {
          name = "${profileChrome}/includes/${name}";
          value = {
            source = "${includesDir}/${name}";
          };
        }) (builtins.filter (n: n != "cascade-colours.css") includeNames)
      );
    in
    includeLinks
    // {
      "${profileChrome}/userChrome.css".source = "${inputs.cascade}/chrome/userChrome.css";
      # Nix-managed colour override (wired to base16 palette)
      "${profileChrome}/includes/cascade-colours.css".text = cascadeColours;
    };
}
