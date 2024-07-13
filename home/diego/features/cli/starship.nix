{
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      format = "$all$directory$character";
      add_newline = false;
      username = {
        show_always = false;
        style_user = "fg:#ef5fff bold";
        style_root = "fg:#9A348E";
        format = "[$user ]($style)";
      };
      character = {
        success_symbol = "[>](bold blue)";
        error_symbol = "[x](bold red)";
        vicmd_symbol = "[Vi](bold green)";
      };
      directory = { home_symbol = ""; };
      time = {

        disabled = true;
      };
      git_commit = { tag_symbol = " tag "; };
      git_status = {
        ahead = ">";
        behind = "<";
        diverged = "<>";
        renamed = "r";
        deleted = "x";

      };
      aws = { symbol = "aws "; };
      c = { symbol = "C "; };
      cobol = { symbol = "cobol "; };
      conda = { symbol = "conda "; };

      directory = { read_only = " ro"; };
      docker_context = {

        symbol = "docker ";
      };

      git_branch = {

        symbol = "git ";
      };

      java = {

        symbol = "java ";
      };

      lua = {

        symbol = "lua ";
      };

      memory_usage = { symbol = "memory "; };

      nix_shell = {

        symbol = "nix ";
      };
      package = {

        symbol = "pkg ";

      };

      python = { symbol = "py "; };

      rust = {

        symbol = "rs ";
      };
      ruby = {

        symbol = "rb ";
      };
      sudo = {
        symbol = "sudo ";

      };
      hostname = {
        ssh_only = true;
        ssh_symbol = "SSH ";
      };
    };

  };
}
