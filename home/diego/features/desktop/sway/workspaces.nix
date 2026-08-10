# Workspace registry — single source of truth for icons, app assignments, and keybindings.
# Consumed by waybar.nix (waybarWorkspaces) and default.nix (registry → assigns, keybindings).
#
# Schema:
#   icon       = Font Awesome hex codepoint (string), e.g. "f0ac"
#   nameless   = true → no default name. The sway target is "<n>:" rather than
#                "<n>", so strip-workspace-numbers leaves an empty label and
#                waybar shows the state icon alone until you rename the
#                workspace. Without the trailing colon there is nothing to
#                strip and the bare number shows instead.
#   persistent = true → show in waybar even when empty
#   app        = sway app_id → used in `assigns` and as the launch-or-focus target
#   key        = letter for Mod4+<key> keybinding
#   launch     = exec command for launch-or-focus (required when `app` and `key` are set)
#   launcher   = custom launcher script (alternative to app+launch, e.g. for yazi)
#   autostart  = int → open this app at login, lowest number first. Launches are
#                staggered, so the order decides which app gets an uncontended
#                start; the session ends focused on the lowest-numbered entry.
#   autostartArgs = extra args appended to `launcher` at login only (not on the
#                keybinding), e.g. the daily-focus prompt for opencode
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
      nameless = true;
    };
    "2" = {
      icon = "f7d9";
      nameless = true;
    };
    "3" = {
      icon = "f7b1";
      nameless = true;
    };
    "4" = {
      icon = "f78d";
      nameless = true;
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
    "10" = {
      icon = "f198";
      app = "Slack";
      launch = "slack";
      key = "c";
      persistent = true;
      autostart = 1;
    };
  };
in
{
  inherit registry;

  # Ready-made waybar "sway/workspaces" module — waybar.nix just splices this in.
  #
  # Format trick: {icon} expands to a pango span that either:
  #   - absorbs {name} at 0.1pt (invisible) for workspaces with dedicated FA icons
  #   - opens a Jost span for {name} on the `nameless` workspaces, which carry a
  #     rename label instead of an icon of their own
  # The format ends with </span> to close whichever span the icon opened.
  waybarWorkspaces =
    let
      absorb = "<span font_size='0.1pt'> "; # makes {name} invisible
      # Shows {name} in Jost. No separator space here: rename-workspace writes
      # "<n>: <label>" and strip-workspace-numbers keeps the leading space, so
      # the gap arrives with the label and a nameless "<n>:" stays icon-only.
      label = "<span font_family='Fantasque Sans Mono'>";
      iconWorkspaces = lib.filterAttrs (_: v: !(v.nameless or false)) registry;
    in
    {
      disable-scroll = false;
      all-outputs = true;
      strip-workspace-numbers = true;
      format = "{icon}{name}</span>";
      format-icons =
        # Icon workspaces: FA icon at 14pt + open absorb span so {name} disappears
        (lib.mapAttrs (_: v: "<span font_size='14pt'>${u v.icon}</span>${absorb}") iconWorkspaces)
        // {
          # `nameless` workspaces fall through to these; open Jost span so a
          # rename label shows, and an empty one collapses to just the icon
          "default" = "<span font_size='14pt'>${u "f22d"}</span>${label}";
          "focused" = "<span font_size='14pt'>${u "f192"}</span>${label}";
          # Let the per-name icons above win over "focused"
          "high-priority-named" = lib.attrNames iconWorkspaces;
        };
      persistent-workspaces = lib.mapAttrs (_: _: [ ]) (
        lib.filterAttrs (_: v: v.persistent or false) registry
      );
    };
}
