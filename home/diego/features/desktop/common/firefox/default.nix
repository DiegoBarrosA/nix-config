{ lib, pkgs, config, inputs, ... }:
let inherit (config.colorscheme) colors;
in {
  programs.firefox = {
    enable = true;
    package = if !pkgs.stdenv.isDarwin then pkgs.firefox-bin else pkgs.dummy;
    profiles.work = {
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.all" = true;
        "svg.context-properties.content.enabled" = true;
        "toolkit.tabbox.switchByScrolling" = true;
        "ui.key.menuAccessKeyFocuses" = false;
        "layout.spellcheckDefault" = 2;
        "browser.urlbar.quickactions.enabled" = true;
        "mousewheel.with_control.action" = 5;
        "browser.sessionstore.resume_from_crash" = false;
        "extensions.unifiedExtensions.enabled" = false;
        "browser.tabs.tabmanager.enabled" = false;
      };

      userChrome = builtins.readFile ./userChrome.css;
    };
  };
}
