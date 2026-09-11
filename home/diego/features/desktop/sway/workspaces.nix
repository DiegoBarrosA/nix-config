{ ... }:
let
  registry = {
    "1" = {
      icon = "f111";
      persistent = true;
    };
    "2" = {
      icon = "f0c8";
      persistent = true;
    };
    "3" = {
      icon = "f219";
      persistent = true;
    };
    "4" = {
      icon = "f005";
      persistent = true;
    };
    "5" = {
      icon = "f0ac";
      app = "firefox-devedition";
      key = "f";
      launch = "firefox-devedition";
      persistent = true;
      autostart = 2;
    };
    "6" = {
      icon = "f674";
      app = "thunderbird";
      key = "g";
      launch = "thunderbird";
      persistent = true;
      autostart = 4;
    };
    "7" = {
      icon = "f802";
      launcher = "yazi-launcher";
      key = "e";
      persistent = true;
      autostart = 5;
    };
    "8" = {
      icon = "f60f";
      app = "obsidian";
      key = "n";
      launch = "obsidian";
      persistent = true;
      autostart = 3;
    };
    "9" = {
      icon = "f1c9";
      launcher = "helix-launcher";
      key = "d";
    };
  };
in
{
  inherit registry;
}
