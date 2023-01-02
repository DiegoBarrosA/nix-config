{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    node2nix

    nodePackages.npm
    nodejs
  ];
}
