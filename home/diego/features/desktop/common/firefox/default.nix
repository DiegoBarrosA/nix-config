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
  };

  stylix.targets.firefox = {
    enable = true;
    profileNames = [ "dev-edition-default" ];
    colorTheme.enable = true;
  };
}
