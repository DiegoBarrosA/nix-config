{ pkgs, config, ... }:
{
  programs.nushell = {
    enable = true;

    shellAliases = {
      # Migrated from fish shellAbbrs
      top = "btm";
      jqless = "jq -C | less -r";
      n = "nix";
      nd = "nix develop -c $env.SHELL";
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
      hms = ''home-manager switch -b $"backup_(date now | format date '%Y-%m-%d_%H-%M-%S')" --flake .'';
      e = "emacsclient -t";
      v = "hx";
      vi = "hx";
      vim = "hx";
      l = "ls";
      lk = "ls";
      ll = "ls";

      # Migrated from fish shellAliases
      getip = "curl ifconfig.me";
      kssh = "kitty +kitten ssh";

      # Zellij alias
      zj = "zellij";
    };

    extraEnv = ''
      # Source nix-daemon for multi-user nix installs (non-NixOS)
      def --env source-bash-env [file: string] {
        if ($file | path exists) {
          bash -c $"source ($file) && env" 
            | lines 
            | where { |line| $line =~ "=" }
            | parse "{key}={value}" 
            | where { |it| $it.key not-in ["_", "SHLVL", "PWD", "FILE_PWD", "CURRENT_FILE"] }
            | transpose -r -d
            | load-env
        }
      }

      # Source nix-daemon if available
      source-bash-env /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

      # Source home-manager session vars (QT_QPA_PLATFORMTHEME, QT_STYLE_OVERRIDE, etc.)
      source-bash-env $"($env.HOME)/.nix-profile/etc/profile.d/hm-session-vars.sh"

      # Ensure home-manager paths are available
      $env.PATH = ($env.PATH | split row (char esep) 
        | prepend $"($env.HOME)/.nix-profile/bin"
        | prepend "/nix/var/nix/profiles/default/bin"
        | uniq)

      # Source MCP environment variables if file exists
      try { source "${config.home.homeDirectory}/.config/nushell/mcp-env.nu" }

      # Ghostty integration - reports working directory
      $env.config = ($env.config? | default {} | merge {
        hooks: {
          pre_prompt: [{
            if "GHOSTY_RESOURCES_DIR" in $env {
              print -n $"\e]7;file://($env.HOSTNAME? | default 'localhost')($env.PWD)\e\\"
            }
          }]
        }
      })
    '';

    extraConfig = ''
      # Disable nushell's default prompt indicators (starship handles this)
      $env.PROMPT_INDICATOR = ""
      $env.EDITOR = "hx"
      $env.PROMPT_INDICATOR_VI_INSERT = ""
      $env.PROMPT_INDICATOR_VI_NORMAL = ""


      # Vi edit mode
      $env.config.edit_mode = "vi"

      # Keybindings
      $env.config.keybindings = ($env.config.keybindings? | default [] | append [
        # Ctrl+T to launch Zellij
        {
          name: launch_zellij
          modifier: control
          keycode: char_t
          mode: [vi_insert vi_normal emacs]
          event: { send: executehostcommand cmd: "zellij" }
        }
        # Alt+E to edit command in editor (like fish)
        {
          name: edit_command
          modifier: alt
          keycode: char_e
          mode: [vi_insert vi_normal emacs]
          event: { send: openeditor }
        }
      ])

      # Custom functions (migrated from fish)

      # Get the real path of a command
      def wh [cmd: string] {
        which $cmd | get path.0 | path expand
      }

      # Create a tar.zst archive
      def tz [path: string] {
        tar -acf $"($path).tar.zst" $path
      }

      # Disable greeting (fish_greeting equivalent)
      $env.config.show_banner = false
    '';
  };

  home.shellAliases = {
    moe = "iina https://listen.moe/stream";
  };
}
