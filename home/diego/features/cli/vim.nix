{ pkgs, ... }: {
  programs.vim = {
    enable = true;

    extraConfig = ''
      autocmd InsertEnter * norm zz
      set clipboard=unnamed
      set number
    '';
  };
  programs.neovim.enable = true;
  home.packages = [ pkgs.neovide ];
}
