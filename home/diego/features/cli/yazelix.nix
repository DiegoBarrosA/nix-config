{ inputs, pkgs, ... }: {
  programs.yazelix = {
    enable = true;
    # Use no-helix variant — helix is already managed by helix.nix
    package = inputs.yazelix.packages.${pkgs.system}.yazelix-no-helix;
    config.settings = {
      shell.program = "nu";
      welcome.enabled = false;
    };
  };
}
