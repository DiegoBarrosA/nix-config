{
  lib,

  labelFont ? "sans-serif",
  ...
}:
let

  u = code: builtins.fromJSON ''"\u${code}"'';

  registry = {
    "1" = {
      icon = "f111";
      nameless = true;
      persistent = true;
    };
    "2" = {
      icon = "f0c8";
      nameless = true;
      persistent = true;
    };
    "3" = {
      icon = "f219";
      nameless = true;
      persistent = true;
    };
    "4" = {
      icon = "f005";
      nameless = true;
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
      icon = "e699";
      launcher = "zellij-agents-launcher";
      key = "z";
      persistent = true;
      autostart = 6;
    };
    "10" = {
      icon = "f544";
      launcher = "opencode-launcher";
      key = "c";
    };
  };
in
{
  inherit registry;

  waybarWorkspaces =
    let
      absorb = "<span font_size='0.1pt'> ";

      label = "<span font_family='${labelFont}'>";
      iconWorkspaces = lib.filterAttrs (_: v: !(v.nameless or false)) registry;
    in
    {
      disable-scroll = false;
      all-outputs = true;
      strip-workspace-numbers = true;
      format = "{icon}{name}</span>";
      format-icons =

        (lib.mapAttrs (_: v: "${u v.icon}${absorb}") iconWorkspaces) // {

          "default" = "${u "f22d"}${label}";
          "focused" = "${u "f192"}${label}";

          "high-priority-named" = lib.attrNames iconWorkspaces;
        };
      persistent-workspaces = lib.mapAttrs' (
        n: v: lib.nameValuePair (if v.nameless or false then "${n}:" else n) [ ]
      ) (lib.filterAttrs (_: v: v.persistent or false) registry);
    };
}
