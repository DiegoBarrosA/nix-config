{ config, lib, pkgs, ... }:

{
  dconf.settings = {
    # Window management
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":minimize,maximize,close";
      focus-mode = "click";
      num-workspaces = 4;
    };

    # Keybindings
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      maximize = [ ];
      minimize = [ ];
      move-to-workspace-1 = [ "<Shift><Super>1" ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
    };

    # Shell keybindings
    "org/gnome/shell/keybindings" = {
      toggle-application-view = [ "<Super>a" ];
      toggle-overview = [ "<Super>d" ];
    };

    # Interface settings
    "org/gnome/desktop/interface" = {
      # Stylix sets gtk-theme via stylix.targets.gnome
      icon-theme = "Papirus-Dark";
      cursor-theme = config.stylix.cursor.name;
      font-name = lib.mkDefault "Cantarell 11";
      document-font-name = lib.mkDefault "Cantarell 11";
      monospace-font-name = lib.mkDefault "${config.fontProfiles.monospace.family} 11";
      color-scheme = lib.mkDefault (
        if config.colorscheme.mode == "light"
        then "prefer-light"
        else "prefer-dark"
      );
      enable-animations = lib.mkDefault true;
    };

    # Extensions
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "blur-my-shell@aunetx"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "dash2dock-lite@icedman.github.com"
        "pop-shell@system76.com"
        "clipboard-indicator@tudmotu.com"
        "caffeine@patapon.info"
        "just-perfection-desktop@just-perfection"
        "Vitals@CoreCoding.com"
      ];
    };

    # Dash2Dock Lite settings
    "org/gnome/shell/extensions/dash2dock-lite" = {
      dock-position = "BOTTOM";
      dash-max-icon-size = 48;
      show-trash = false;
      show-mounts = false;
      autohide = true;
      intellihide = true;
    };

    # Pop Shell settings
    "org/gnome/shell/extensions/pop-shell" = {
      tile-by-default = false;
      gap-inner = 4;
      gap-outer = 4;
    };

    # Blur My Shell settings
    "org/gnome/shell/extensions/blur-my-shell" = {
      blur-dash = true;
      blur-panel = true;
      blur-overview = true;
    };

    # Just Perfection settings
    "org/gnome/shell/extensions/just-perfection" = {
      dash = true;
      window-demands-attention-focus = true;
    };

    # Caffeine settings
    "org/gnome/shell/extensions/caffeine" = {
      enable-fullscreen = true;
      show-indicator = "always";
    };
  };
}
