{ ... }:
{
  flake.modules.homeManager.desktop-common-swayimg =
{ config, ... }: let
  inherit (config.colorscheme) colors;
  inherit (config.stylix) fonts;
  argb = c: "0xff${c}";
in {
  programs.swayimg = {
    enable = true;

    # swayimg 5.x reads a Lua config. Colors are 0xAARRGGBB.
    initLua = ''
      swayimg.text.font = "${fonts.monospace.name}"
      swayimg.text.size = ${toString fonts.sizes.applications}
      swayimg.text.color = ${argb colors.base05}
      swayimg.text.background = 0x00000000
      swayimg.text.shadow = 0x00000000

      swayimg.viewer.set_window_background(${argb colors.base00})
      swayimg.viewer.set_image_chessboard(20, ${argb colors.base01}, ${argb colors.base02})

      swayimg.slideshow.set_window_background(${argb colors.base00})

      swayimg.gallery.window_color = ${argb colors.base00}
      swayimg.gallery.unselected_color = ${argb colors.base01}
      swayimg.gallery.selected_color = ${argb colors.base02}
      swayimg.gallery.border_color = ${argb colors.base0D}

      -- Vim keybindings
      local step = 50

      local function pan(dx, dy)
        return function()
          local pos = swayimg.viewer.get_position()
          swayimg.viewer.set_abs_position(pos.x + dx, pos.y + dy)
        end
      end

      for _, mode in ipairs({ swayimg.viewer, swayimg.slideshow, swayimg.gallery }) do
        mode.on_key("q", function() swayimg.exit() end)
      end

      -- Viewer: hjkl pans, H/L previous/next image, g/G first/last
      swayimg.viewer.on_key("h", pan(step, 0))
      swayimg.viewer.on_key("l", pan(-step, 0))
      swayimg.viewer.on_key("k", pan(0, step))
      swayimg.viewer.on_key("j", pan(0, -step))
      swayimg.viewer.on_key("Ctrl+u", pan(0, step * 6))
      swayimg.viewer.on_key("Ctrl+d", pan(0, -step * 6))
      swayimg.viewer.on_key("Shift+h", function() swayimg.viewer.open("prev") end)
      swayimg.viewer.on_key("Shift+l", function() swayimg.viewer.open("next") end)
      swayimg.viewer.on_key("g", function() swayimg.viewer.open("first") end)
      swayimg.viewer.on_key("Shift+g", function() swayimg.viewer.open("last") end)
      swayimg.viewer.on_key("plus", function()
        swayimg.viewer.scale = swayimg.viewer.scale * 1.1
      end)
      swayimg.viewer.on_key("0", function() swayimg.viewer.reset() end)

      -- Gallery: hjkl selects, g/G first/last, Ctrl-d/u page down/up
      swayimg.gallery.on_key("h", function() swayimg.gallery.select("left") end)
      swayimg.gallery.on_key("l", function() swayimg.gallery.select("right") end)
      swayimg.gallery.on_key("k", function() swayimg.gallery.select("up") end)
      swayimg.gallery.on_key("j", function() swayimg.gallery.select("down") end)
      swayimg.gallery.on_key("g", function() swayimg.gallery.select("first") end)
      swayimg.gallery.on_key("Shift+g", function() swayimg.gallery.select("last") end)
      swayimg.gallery.on_key("Ctrl+d", function() swayimg.gallery.select("pgdown") end)
      swayimg.gallery.on_key("Ctrl+u", function() swayimg.gallery.select("pgup") end)
    '';
  };

  xdg.mimeApps.defaultApplications = {
    "image/avif" = [ "swayimg.desktop" ];
    "image/bmp" = [ "swayimg.desktop" ];
    "image/gif" = [ "swayimg.desktop" ];
    "image/jpeg" = [ "swayimg.desktop" ];
    "image/png" = [ "swayimg.desktop" ];
    "image/svg+xml" = [ "swayimg.desktop" ];
    "image/tiff" = [ "swayimg.desktop" ];
    "image/webp" = [ "swayimg.desktop" ];
    "image/x-icns" = [ "swayimg.desktop" ];
    "image/x-icon" = [ "swayimg.desktop" ];
    "image/x-xcf" = [ "swayimg.desktop" ];
  };
};
}
