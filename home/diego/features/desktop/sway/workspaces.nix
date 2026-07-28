# Workspace registry — single source of truth for icons, app assignments, and keybindings.
# Consumed by waybar.nix (format-icons, persistent-workspaces) and default.nix (assigns, keybindings).
#
# Schema:
#   icon       = Font Awesome hex codepoint (string), e.g. "f0ac"
#   persistent = true → show in waybar even when empty
#   app        = sway app_id → used in `assigns` and as the launch-or-focus target
#   key        = letter for Mod4+<key> keybinding
#   launch     = exec command for launch-or-focus (required when `app` is set and `key` is set)
#   launcher   = custom launcher script (alternative to app+launch, e.g. for yazi)
#
# Adding a new app: add one entry here. Waybar icon, workspace assignment,
# and keybinding all derive from this file automatically.
{
  "1"  = { icon = "f61f"; persistent = true; };
  "2"  = { icon = "f7d9"; persistent = true; };
  "3"  = { icon = "f7b1"; persistent = true; };
  "4"  = { icon = "f78d"; persistent = true; };
  "5"  = { icon = "f0ac"; app = "firefox-devedition"; key = "f"; launch = "firefox-devedition"; };
  "6"  = { icon = "f674"; app = "thunderbird";        key = "g"; launch = "thunderbird"; };
  "7"  = { icon = "f802"; launcher = "yazi-launcher"; key = "e"; };
  "8"  = { icon = "f60f"; app = "obsidian";           key = "n"; launch = "obsidian"; };
  "9"  = { icon = "f1c9"; };
  "10" = { icon = "f086"; };
}
