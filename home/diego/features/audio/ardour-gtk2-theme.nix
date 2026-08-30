{ pkgs, ... }:
{
  xdg.configFile."gtk-2.0/ardour-flat/gtkrc".text = ''
    gtk-theme-name = "Default"
    gtk-icon-theme-name = "Papirus-Dark"
    gtk-cursor-theme-name = "Bibata-Modern-Classic"
    gtk-cursor-theme-size = 28
    gtk-toolbar-style = GTK_TOOLBAR_ICONS
    gtk-toolbar-icon-size = GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images = 0
    gtk-menu-images = 0
    gtk-enable-event-sounds = 0
    gtk-enable-input-feedback-sounds = 0
    gtk-xft-antialias = 1
    gtk-xft-hinting = 1
    gtk-xft-hintstyle = "hintslight"
    gtk-xft-rgba = "rgb"

    class "GtkWidget" style "ardour-flat-widget"
    class "GtkButton" style "ardour-flat-button"
    class "GtkEntry" style "ardour-flat-entry"
    class "GtkTextView" style "ardour-flat-entry"
    class "GtkComboBox" style "ardour-flat-entry"
    class "GtkSpinButton" style "ardour-flat-entry"
    class "GtkScrolledWindow" style "ardour-flat-scroll"
    class "GtkScale" style "ardour-flat-scale"
    class "GtkMenuBar" style "ardour-flat-menubar"
    class "GtkMenu" style "ardour-flat-menu"
    class "GtkMenuItem" style "ardour-flat-menuitem"
    class "GtkToolbar" style "ardour-flat-toolbar"
    class "GtkNotebook" style "ardour-flat-notebook"
    class "GtkPaned" style "ardour-flat-paned"
    class "GtkHandleBox" style "ardour-flat-handle"
    class "GtkFrame" style "ardour-flat-frame"
    class "GtkTreeView" style "ardour-flat-tree"
    class "GtkIconView" style "ardour-flat-tree"
    class "GtkProgressBar" style "ardour-flat-progress"

    style "ardour-flat-widget" {
      xthickness = 0
      ythickness = 0
    }

    style "ardour-flat-button" {
      xthickness = 1
      ythickness = 1

      GtkWidget::focus-line-width = 0
      GtkWidget::focus-padding = 0
      GtkWidget::interior-focus = 0
      GtkButton::child-displacement-x = 0
      GtkButton::child-displacement-y = 0
      GtkButton::default-border = { 0, 0, 0, 0 }
      GtkButton::default-outset-border = { 0, 0, 0, 0 }
      GtkButton::image-spacing = 4
      GtkButton::request-detail = 0

      bg[NORMAL] = @theme_bg_color
      bg[PRELIGHT] = shade(1.04, @theme_bg_color)
      bg[SELECTED] = @theme_bg_color
      bg[ACTIVE] = shade(0.9, @theme_bg_color)
      bg[INSENSITIVE] = @theme_bg_color

      fg[NORMAL] = @theme_fg_color
      fg[PRELIGHT] = @theme_fg_color
      fg[SELECTED] = @theme_fg_color
      fg[ACTIVE] = @theme_fg_color
      fg[INSENSITIVE] = mix(0.5, @theme_fg_color, @theme_bg_color)
    }

    style "ardour-flat-entry" {
      xthickness = 2
      ythickness = 2

      GtkWidget::focus-line-width = 0
      GtkWidget::focus-padding = 0
      GtkWidget::interior-focus = 0
      GtkEntry::honors-transparent-bg-hint = 1
      GtkEntry::state-hint = 0

      bg[NORMAL] = @theme_base_color
      bg[PRELIGHT] = @theme_base_color
      bg[SELECTED] = mix(0.4, @theme_bg_color, @theme_selected_bg_color)
      bg[ACTIVE] = @theme_base_color
      bg[INSENSITIVE] = @theme_bg_color

      fg[NORMAL] = @theme_text_color
      fg[PRELIGHT] = @theme_text_color
      fg[SELECTED] = @theme_text_color
      fg[ACTIVE] = @theme_text_color
      fg[INSENSITIVE] = mix(0.5, @theme_fg_color, @theme_bg_color)
    }

    style "ardour-flat-scroll" {
      bg[NORMAL] = @theme_bg_color
      bg[INSENSITIVE] = @theme_bg_color
    }

    style "ardour-flat-scale" {
      xthickness = 0
      ythickness = 0

      bg[NORMAL] = @theme_bg_color
      bg[PRELIGHT] = @theme_bg_color
      bg[ACTIVE] = @theme_bg_color
    }

    style "ardour-flat-menubar" {
      xthickness = 0
      ythickness = 0

      bg[NORMAL] = @theme_bg_color
      bg[PRELIGHT] = shade(1.04, @theme_bg_color)
      bg[SELECTED] = @theme_bg_color
      bg[ACTIVE] = shade(0.9, @theme_bg_color)
      bg[INSENSITIVE] = @theme_bg_color

      fg[NORMAL] = @theme_fg_color
      fg[PRELIGHT] = @theme_fg_color
      fg[SELECTED] = @theme_fg_color
      fg[ACTIVE] = @theme_fg_color
      fg[INSENSITIVE] = mix(0.5, @theme_fg_color, @theme_bg_color)
    }

    style "ardour-flat-menu" {
      xthickness = 0
      ythickness = 0

      bg[NORMAL] = @theme_bg_color
      bg[SELECTED] = @theme_selected_bg_color

      fg[NORMAL] = @theme_fg_color
      fg[SELECTED] = @theme_selected_fg_color
    }

    style "ardour-flat-menuitem" {
      xthickness = 2
      ythickness = 2

      bg[PRELIGHT] = @theme_selected_bg_color

      fg[NORMAL] = @theme_fg_color
      fg[PRELIGHT] = @theme_selected_fg_color
    }

    style "ardour-flat-toolbar" {
      xthickness = 0
      ythickness = 0

      bg[NORMAL] = @theme_bg_color
      bg[PRELIGHT] = shade(1.04, @theme_bg_color)
      bg[ACTIVE] = shade(0.9, @theme_bg_color)

      fg[NORMAL] = @theme_fg_color
      fg[PRELIGHT] = @theme_fg_color
      fg[ACTIVE] = @theme_fg_color
    }

    style "ardour-flat-notebook" {
      xthickness = 0
      ythickness = 0

      bg[NORMAL] = @theme_bg_color
      bg[ACTIVE] = @theme_bg_color
      bg[PRELIGHT] = @theme_bg_color

      fg[NORMAL] = @theme_fg_color
      fg[ACTIVE] = @theme_fg_color

      GtkNotebook::tab-overlap = 0
    }

    style "ardour-flat-paned" {
      xthickness = 0
      ythickness = 0
    }

    style "ardour-flat-handle" {
      xthickness = 0
      ythickness = 0
    }

    style "ardour-flat-frame" {
      xthickness = 0
      ythickness = 0
    }

    style "ardour-flat-tree" {
      bg[NORMAL] = @theme_base_color
      bg[SELECTED] = @theme_selected_bg_color

      fg[NORMAL] = @theme_text_color
      fg[SELECTED] = @theme_selected_fg_color
    }

    style "ardour-flat-progress" {
      bg[NORMAL] = @theme_bg_color
      bg[PRELIGHT] = @theme_bg_color

      fg[NORMAL] = @theme_fg_color
    }
  '';

  xdg.configFile."gtk-2.0/ardour-flat/index.theme".text = ''
    [Desktop Entry]
    Name=Ardour Flat
    Type=X-GNOME-Metatheme
    Comment=A flat, square, depthless theme for Ardour

    [X-GNOME-Metatheme]
    GtkTheme=ardour-flat
    IconTheme=Papirus-Dark
    CursorTheme=Bibata-Modern-Classic
    MetacityTheme=Adwaita
    ButtonLayout=close,minimize,maximize:menu
  '';
}
