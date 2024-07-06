{
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "hx";
      top = "btm";
    };

    extraConfig = ''
                use ~/.cache/starship/init.nu
                 $env.config = {  
                    edit_mode: vi,
                   show_banner: false

      cursor_shape: {
        emacs: line # block, underscore, line, blink_block, blink_underscore, blink_line (line is the default)
        vi_insert: line  # block, underscore, line , blink_block, blink_underscore, blink_line (block is the default)
        vi_normal: block # block, underscore, line, blink_block, blink_underscore, blink_line (underscore is the default)
      }
                  
                  }

          $env.STARSHIP_SHELL = "nu"

          def create_left_prompt [] {
              starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
          }

          # Use nushell functions to define your right and left prompt
          $env.PROMPT_COMMAND = { || create_left_prompt }
          $env.PROMPT_COMMAND_RIGHT = ""

          # The prompt indicators are environmental variables that represent
          # the state of the prompt
          $env.PROMPT_INDICATOR = ""
          $env.PROMPT_INDICATOR_VI_INSERT = ""
          $env.PROMPT_INDICATOR_VI_NORMAL = "vi"
          $env.PROMPT_MULTILINE_INDICATOR = "::: "    '';
  };
}
