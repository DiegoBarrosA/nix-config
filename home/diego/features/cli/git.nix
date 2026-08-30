{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    signing = {
      format = null;
    };

    ignores = [
      ".direnv"
      "result"
    ];

    settings = {

      url."https://github.com/" = {
        insteadOf = "git://github.com/";
      };
      alias = {
        pushall = "!git remote | xargs -L1 git push --all";
        graph = "log --decorate --oneline --graph";
      };
      user = {

        name = "DiegoBarrosA";
        email = "diegobarrosaraya@outlook.com";
      };
      init = {
        feature.manyFiles = true;
        init.defaultBranch = "main";
      };
      lfs = {
        enable = true;
      };

    };
  };
}
