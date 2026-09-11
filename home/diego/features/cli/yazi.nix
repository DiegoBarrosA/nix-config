{ pkgs, config, ... }:
let

  hx-open = pkgs.writeShellScriptBin "hx-open" ''
    FILE=$(realpath "$1")
    if [ -n "''${ZELLIJ:-}" ]; then
      zellij action move-focus right
      sleep 0.05
      zellij action write-chars ":open $FILE"
      zellij action write 13
      zellij action move-focus left
    else
      hx "$FILE"
    fi
  '';
in
{
  home.packages = with pkgs; [ ueberzugpp hx-open ];

  # The opencode profile sets XDG_CONFIG_HOME to a profile-specific dir,
  # which makes Yazi look for config in the wrong place and silently drop
  # all custom keybindings. Pin YAZI_CONFIG_HOME explicitly.
  home.sessionVariables.YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    settings = {
      icon.enable = false;

      preview = {
        max_width = 1000;
        max_height = 1000;
        ueberzug_scale = 1;
      };
    };
    keymap.manager.prepend_keymap = [
      {
        on = [ "e" ];
        run = ''shell 'hx-open "$1"' --confirm'';
        desc = "Open in Helix (Zellij dev layout)";
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
        run = "cd ~/Projects/ServiceRocket";
        desc = "Go to Projects/ServiceRocket";
      }
      {
        on = [ "g" "p" ];
        run = "cd ~/Projects/Personal";
        desc = "Go to Projects/Personal";
      }
      {
        on = [ "g" "c" ];
        run = [
          "shell 'mkdir -p ~/mnt/cobalto; mountpoint -q ~/mnt/cobalto || sshfs cobalto: ~/mnt/cobalto' --confirm"
          "cd ~/mnt/cobalto"
        ];
        desc = "Go to cobalto (sshfs)";
      }
      {
        on = [ "g" "m" ];
        run = [
          "shell 'device-mount' --confirm"
          "cd ~/mnt"
        ];
        desc = "Mount detected device";
      }
      {
        on = [ "g" "M" ];
        run = "shell 'device-umount' --confirm";
        desc = "Unmount detected device";
      }
      {
        on = [ "g" "u" ];
        run = "cd /run/media";
        desc = "Go to udiskie media mounts";
      }
      {
        on = [ "g" "i" ];
        run = "cd ~/mnt/iphone";
        desc = "Go to iPhone mount";
      }
      {
        on = [ "g" "a" ];
        run = "cd ~/mnt/droid";
        desc = "Go to Android (MTP) mount";
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

  xdg.dataFile."applications/yazi-fm.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Yazi
      Exec=alacritty -e yazi
      Categories=FileManager;
      MimeType=inode/directory;
    '';
  };
}
