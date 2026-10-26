{ ... }:
{
  flake.modules.homeManager.cli-yazi =
{ pkgs, config, ... }:
{
  home.packages = with pkgs; [ ueberzugpp ];

  # The opencode profile sets XDG_CONFIG_HOME to a profile-specific dir,
  # which makes Yazi look for config in the wrong place and silently drop
  # all custom keybindings. Pin YAZI_CONFIG_HOME explicitly.
  home.sessionVariables.YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    plugins = {
      bookmarks = pkgs.yaziPlugins.bookmarks;
      gridview = pkgs.fetchFromGitHub {
        owner = "skylightlim";
        repo = "gridview.yazi";
        rev = "4c7a2b1367109c351cc50c2267c1c456cc97d75b";
        hash = "sha256-YlHribBCESv+9SQ89HAUsC1k+Rsb6s4vTSjtFkfAzus=";
      };
    };
    initLua = ''
      require("bookmarks"):setup({
        persist = "all",
        show_keys = true,
        notify = { enable = true },
      })
    '';
    settings = {
      icon.enable = false;

      preview = {
        max_width = 1000;
        max_height = 1000;
        ueberzug_scale = 1;
      };

    };
    keymap.mgr.prepend_keymap = [
      {
        on = [ "g" "v" ];
        run = "plugin gridview";
        desc = "Image grid view (swayimg)";
      }
      {
        on = [ "m" ];
        run = "plugin bookmarks save";
        desc = "Save current position as a bookmark";
      }
      {
        on = [ "'" ];
        run = "plugin bookmarks jump";
        desc = "Jump to a bookmark (list of all)";
      }
      {
        on = [ "b" "d" ];
        run = "plugin bookmarks delete";
        desc = "Delete a bookmark";
      }
      {
        on = [ "b" "D" ];
        run = "plugin bookmarks delete_all";
        desc = "Delete all bookmarks";
      }
      {
        on = [ "g" "h" ];
        run = "cd ~";
        desc = "Go to home";
      }
      {
        on = [ "g" "d" ];
        run = "cd ~/Downloads";
        desc = "Go to Downloads";
      }
      {
        on = [ "g" "n" ];
        run = "cd ~/Projects/Personal/nix/nix-config";
        desc = "Go to nix-config";
      }
      {
        on = [ "g" "N" ];
        run = "cd ~/Projects/NVIDIA";
        desc = "Go to Projects/NVIDIA";
      }
      {
        on = [ "g" "s" ];
        run = "cd ~/Projects/Work";
        desc = "Go to Projects/Work";
      }
      {
        on = [ "g" "p" ];
        run = "cd ~/Projects/Personal";
        desc = "Go to Projects/Personal";
      }
      {
        on = [ "g" "u" ];
        run = "cd /run/media";
        desc = "Go to udiskie media mounts";
      }
    ];
    theme = {
      status = {
        sep_left = { open = ""; close = ""; };
        sep_right = { open = ""; close = ""; };
      };
      icon = {
        globs = [ ];
        dirs = [ ];
        files = [ ];
        exts = [ ];
        conds = [ ];
      };
    };
  };
}
;
}
