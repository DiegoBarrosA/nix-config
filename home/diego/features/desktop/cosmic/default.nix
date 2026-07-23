{ pkgs, ... }:
{
  # Disable Sway-specific kanshi (COSMIC manages outputs itself)
  rubi.desktop.manageKanshi = false;

  # Barebones app set: settings + file manager. Everything else from common/ + TUI.
  home.packages = with pkgs; [
    cosmic-settings
    cosmic-files
  ];

  # Alacritty client-side decorations (COSMIC provides its own title bar)
  programs.alacritty.settings.window.decorations = "full";

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "COSMIC";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
  };
}
