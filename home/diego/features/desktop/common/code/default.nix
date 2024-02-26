{ config, pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      ms-python.python
      ms-azuretools.vscode-docker
      ms-vscode-remote.remote-ssh
      bbenoist.nix
    ];
  };
}
