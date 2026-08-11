# Workspace registry — single source of truth for app assignments and keybindings.
# Consumed by default.nix (registry → assigns, keybindings, session-apps autostart).
#
# Schema:
#   app        = sway app_id → used in `assigns` and as the launch-or-focus target
#   key        = letter for Mod4+<key> keybinding
#   launch     = exec command for launch-or-focus (required when `app` and `key` are set)
#   launcher   = custom launcher script (alternative to app+launch, e.g. for yazi)
#   autostart  = int → open this app at login, lowest number first. Launches are
#                staggered, so the order decides which app gets an uncontended
#                start; the session ends focused on the lowest-numbered entry.
#   autostartArgs = extra args appended to `launcher` at login only (not on the
#                keybinding), e.g. the daily-focus prompt for opencode
#   name       = fixed label. The workspace is created as "<n>: <name>" instead
#                of a bare number; `workspace number <n>` still matches it, so
#                nothing else needs to know about the label.
#   persistent = true → pre-create this (named) workspace at login even if its
#                app never autostarts, so it always shows in the bar instead of
#                only appearing once you switch to it. See default.nix's
#                session-apps warmup step.
#
# Workspaces not listed here (1-4) are general-purpose: no app, no autostart.
#
# Adding a new app: add one entry here. Workspace assignment and keybinding
# both derive from this file automatically.
{ ... }:
let
  registry = {
    "5" = {
      app = "firefox-devedition";
      key = "f";
      launch = "firefox-devedition";
      autostart = 2;
      name = "Web";
      persistent = true;
    };
    "6" = {
      app = "thunderbird";
      key = "g";
      launch = "thunderbird";
      autostart = 4;
      name = "Mail";
      persistent = true;
    };
    "7" = {
      launcher = "yazi-launcher";
      key = "e";
      autostart = 5;
      name = "Files";
      persistent = true;
    };
    "8" = {
      app = "obsidian";
      key = "n";
      launch = "obsidian";
      autostart = 3;
      name = "Notes";
      persistent = true;
    };
    "9" = {
      launcher = "helix-launcher";
      key = "d";
      name = "Code";
      persistent = true;
    };
    "10" = {
      app = "Slack";
      launch = "slack";
      autostart = 1;
      name = "Chat";
      persistent = true;
    };
  };
in
{
  inherit registry;
}
