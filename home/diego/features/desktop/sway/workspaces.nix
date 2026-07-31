# Workspace registry — single source of truth for icons, app assignments, and keybindings.
# Consumed by waybar.nix (waybarWorkspaces) and default.nix (registry → assigns, keybindings).
#
# Schema:
#   icon       = Font Awesome hex codepoint (string), e.g. "f0ac"
#   persistent = true → show in waybar even when empty
#   app        = sway app_id → used in `assigns` and as the launch-or-focus target
#   key        = letter for Mod4+<key> keybinding
#   launch     = exec command for launch-or-focus (required when `app` and `key` are set)
#   launcher   = custom launcher script (alternative to app+launch, e.g. for yazi)
#
# Adding a new app: add one entry here. Waybar icon, workspace assignment,
# and keybinding all derive from this file automatically.
{ lib, ... }:
let
  # Decode a \uXXXX escape to the actual Unicode character
  u = code: builtins.fromJSON ''"\u${code}"'';

  registry = {
    "1" = {
      icon = "f61f";
    };
    "2" = {
      icon = "f7d9";
    };
    "3" = {
      icon = "f7b1";
    };
    "4" = {
      icon = "f78d";
    };
    "5" = {
      icon = "f0ac";
      app = "firefox-devedition";
      key = "f";
      launch = "firefox-devedition";
      persistent = true;
    };
    "6" = {
      icon = "f674";
      app = "thunderbird";
      key = "g";
      launch = "thunderbird";
      persistent = true;
    };
    "7" = {
      icon = "f802";
      launcher = "yazi-launcher";
      key = "e";
      persistent = true;
    };
    "8" = {
      icon = "f60f";
      app = "obsidian";
      key = "n";
      launch = "obsidian";
      persistent = true;
    };
    "9" = {
      icon = "f1c9";
      launcher = "helix-launcher";
      key = "d";
    };
    "10" = {
      icon = "f086";
    };
  };
in
{
  inherit registry;

  # Ready-made waybar "sway/workspaces" module — waybar.nix just splices this in.
  #
  # Format trick: {icon} expands to a pango span that either:
  #   - absorbs {name} at 0.1pt (invisible) for workspaces 5-10 with dedicated FA icons
  #   - opens a Jost span for {name} for workspaces 1-4 (label-only workspaces)
  # The format ends with </span> to close whichever span the icon opened.
  waybarWorkspaces =
    let
      absorb = "<span font_size='0.1pt'> "; # makes {name} invisible
      label = "<span font_family='Fantasque Sans Mono'> "; # shows {name} in Jost
    in
    {
      disable-scroll = false;
      all-outputs = true;
      strip-workspace-numbers = true;
      format = "{icon}{name}</span>";
      format-icons =
        # 5-10: FA icon at 14pt + open absorb span so {name} (the bare number) disappears
        (lib.mapAttrs (_: v: "<span font_size='14pt'>${u v.icon}</span>${absorb}") (
          lib.filterAttrs (
            n: _:
            !(lib.elem n [
              "1"
              "2"
              "3"
              "4"
            ])
          ) registry
        ))
        // {
          # 1-4 fall through to these; open Jost span so renamed labels show
          "default" = "<span font_size='14pt'>${u "f22d"}</span>${label}";
          "focused" = "<span font_size='14pt'>${u "f192"}</span>${label}";
          "high-priority-named" = lib.filter (
            n:
            !(lib.elem n [
              "1"
              "2"
              "3"
              "4"
            ])
          ) (lib.attrNames registry);
        };
      persistent-workspaces = lib.mapAttrs (_: _: [ ]) (
        lib.filterAttrs (_: v: v.persistent or false) registry
      );
    };
}
