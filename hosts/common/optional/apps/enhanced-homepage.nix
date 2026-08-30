{ config, lib, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    glances
  ];

  services.glances = {
    enable = true;
    port = 61208;
    openFirewall = true;
  };

  system.activationScripts.homepage-config = ''
    mkdir -p /nix/storage/homepage

    if [ ! -f /nix/storage/homepage/services.yaml ]; then
      cp ${./homepage-config/services.yaml} /nix/storage/homepage/services.yaml
    fi

    if [ ! -f /nix/storage/homepage/settings.yaml ]; then
      cp ${./homepage-config/settings.yaml} /nix/storage/homepage/settings.yaml
    fi

    if [ ! -f /nix/storage/homepage/widgets.yaml ]; then
      cp ${./homepage-config/widgets.yaml} /nix/storage/homepage/widgets.yaml
    fi

    if [ ! -f /nix/storage/homepage/bookmarks.yaml ]; then
      cat > /nix/storage/homepage/bookmarks.yaml << 'EOF'
---
- Development:
    - GitHub:
        - href: https://github.com/DiegoBarrosA/nix-config
          description: This NixOS configuration repository
          icon: github.png

    - NixOS:
        - href: https://nixos.org
          description: NixOS homepage
          icon: nixos.png
        - href: https://search.nixos.org/packages
          description: NixOS package search
          icon: nixos.png

- Documentation:
    - Services:
        - href: https://jellyfin.org/docs/
          description: Jellyfin documentation
          icon: jellyfin.png
        - href: https://docs.portainer.io/
          description: Portainer documentation
          icon: portainer.png
EOF
    fi

    chown -R 1000:1000 /nix/storage/homepage
    chmod -R 644 /nix/storage/homepage/*.yaml
  '';

  networking.firewall = {
    allowedTCPPorts = [
      8082
      61208
    ];
  };
}