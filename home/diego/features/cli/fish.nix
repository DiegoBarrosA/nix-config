{ pkgs, lib, ... }:
let
  inherit (pkgs) stdenv;
  inherit (lib) mkIf;
in {
  programs.fish = {
    enable = true;
    shellAbbrs = {
      top = "${pkgs.bottom}/bin/btm";
      jqless = "jq -C | less -r";
      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";
      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";
      moe = "iina https://listen.moe/stream";
      up =
        "home-manager switch -b backup --flake  /Users/diego/Documents/Repos/nix-config";
      e = "emacsclient -t";
      v = "hx";
      vi = "hx";
    };
    shellAliases = {
      # Get ip
      getip = "curl ifconfig.me";
      # SSH with kitty terminfo
      kssh = "kitty +kitten ssh";
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };
    functions = {
      fish_greeting = "";
      wh = "readlink -f (which $argv)";
      tz = "tar -acf $argv.tar.zst $argv";
    };

    interactiveShellInit =
      # Open command buffer in vim when alt+e is pressed
      ''
        bind \ee edit_command_buffer
      '' +
      # alacritty integration
      ''
        complete -c alacritty -n "__fish_use_subcommand" -l embed -d 'X11 window ID to embed Alacritty within (decimal or hexadecimal with "0x" prefix)' -r
        complete -c alacritty -n "__fish_use_subcommand" -l config-file -d 'Specify alternative configuration file [default: $XDG_CONFIG_HOME/alacritty/alacritty.yml]' -r -F
        complete -c alacritty -n "__fish_use_subcommand" -l socket -d 'Path for IPC socket creation' -r -F
        complete -c alacritty -n "__fish_use_subcommand" -s o -l option -d 'Override configuration file options [example: cursor.style=Beam]' -r
        complete -c alacritty -n "__fish_use_subcommand" -l working-directory -d 'Start the shell in the specified working directory' -r -F
        complete -c alacritty -n "__fish_use_subcommand" -s e -l command -d 'Command and args to execute (must be last argument)' -r
        complete -c alacritty -n "__fish_use_subcommand" -s t -l title -d 'Defines the window title [default: Alacritty]' -r
        complete -c alacritty -n "__fish_use_subcommand" -l class -d 'Defines window class/app_id on X11/Wayland [default: Alacritty]' -r
        complete -c alacritty -n "__fish_use_subcommand" -s h -l help -d 'Print help information'
        complete -c alacritty -n "__fish_use_subcommand" -s V -l version -d 'Print version information'
        complete -c alacritty -n "__fish_use_subcommand" -l print-events -d 'Print all events to stdout'
        complete -c alacritty -n "__fish_use_subcommand" -l ref-test -d 'Generates ref test'
        complete -c alacritty -n "__fish_use_subcommand" -s q -d 'Reduces the level of verbosity (the min level is -qq)'
        complete -c alacritty -n "__fish_use_subcommand" -s v -d 'Increases the level of verbosity (the max level is -vvv)'
        complete -c alacritty -n "__fish_use_subcommand" -l hold -d 'Remain open after child process exit'
        complete -c alacritty -n "__fish_use_subcommand" -f -a "msg" -d 'Send a message to the Alacritty socket'
        complete -c alacritty -n "__fish_use_subcommand" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and not __fish_seen_subcommand_from create-window; and not __fish_seen_subcommand_from config; and not __fish_seen_subcommand_from help" -s s -l socket -d 'IPC socket connection path override' -r -F
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and not __fish_seen_subcommand_from create-window; and not __fish_seen_subcommand_from config; and not __fish_seen_subcommand_from help" -s h -l help -d 'Print help information'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and not __fish_seen_subcommand_from create-window; and not __fish_seen_subcommand_from config; and not __fish_seen_subcommand_from help" -f -a "create-window" -d 'Create a new window in the same Alacritty process'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and not __fish_seen_subcommand_from create-window; and not __fish_seen_subcommand_from config; and not __fish_seen_subcommand_from help" -f -a "config" -d 'Update the Alacritty configuration'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and not __fish_seen_subcommand_from create-window; and not __fish_seen_subcommand_from config; and not __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from create-window" -l working-directory -d 'Start the shell in the specified working directory' -r -F
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from create-window" -s e -l command -d 'Command and args to execute (must be last argument)' -r
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from create-window" -s t -l title -d 'Defines the window title [default: Alacritty]' -r
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from create-window" -l class -d 'Defines window class/app_id on X11/Wayland [default: Alacritty]' -r
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from create-window" -l hold -d 'Remain open after child process exit'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from create-window" -s h -l help -d 'Print help information'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from config" -s w -l window-id -d 'Window ID for the new config' -r
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from config" -s r -l reset -d 'Clear all runtime configuration changes'
        complete -c alacritty -n "__fish_seen_subcommand_from msg; and __fish_seen_subcommand_from config" -s h -l help -d 'Print help information'
      '' +
      # Use vim bindings and cursors
      ''
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
      '' +
      #use clipboard on vi mode
      ''
        function fish_user_key_bindings
          bind yy fish_clipboard_copy
          bind Y fish_clipboard_copy
          bind p fish_clipboard_paste
        bind dd  'fish_clipboard_copy && commandline -r ""' 
        end
      '' +
      # Use terminal colors
      ''
        set -U fish_color_autosuggestion      brblack
        set -U fish_color_cancel              -r
        set -U fish_color_command             brgreen
        set -U fish_color_comment             brmagenta
        set -U fish_color_cwd                 green
        set -U fish_color_cwd_root            red
        set -U fish_color_end                 brmagenta
        set -U fish_color_error               brred
        set -U fish_color_escape              brcyan
        set -U fish_color_history_current     --bold
        set -U fish_color_host                normal
        set -U fish_color_match               --background=brblue
        set -U fish_color_normal              normal
        set -U fish_color_operator            cyan
        set -U fish_color_param               brblue
        set -U fish_color_quote               yellow
        set -U fish_color_redirection         bryellow
        set -U fish_color_search_match        'bryellow' '--background=brblack'
        set -U fish_color_selection           'white' '--bold' '--background=brblack'
        set -U fish_color_status              red
        set -U fish_color_user                brgreen
        set -U fish_color_valid_path          --underline
        set -U fish_pager_color_completion    normal
        set -U fish_pager_color_description   yellow
        set -U fish_pager_color_prefix        'white' '--bold' '--underline'
        set -U fish_pager_color_progress      'brwhite' '--background=cyan'
      '';
  };
}
