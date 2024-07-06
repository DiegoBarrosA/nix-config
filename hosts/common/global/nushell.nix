{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.any-nix-shell ];
  programs.fish = {
    enable = true;
    promptInit = ''
      any-nix-shell fish --info-right | source
    '';
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };
}
