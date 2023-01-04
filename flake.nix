{
  description = "Your new nix config";

  inputs = {

    hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    musnix.url = "github:musnix/musnix";
    darwin =  {
      url = "github:lnl7/nix-darwin/master";
    inputs.nixpkgs.follows = "nixpkgs";
           };
    nix-on-droid = {
      url = "github:t184256/nix-on-droid/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/hyprland/v0.19.2beta";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";

      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, darwin, nix-on-droid, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs.lib) filterAttrs traceVal;
      inherit (builtins) mapAttrs elem;
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in rec {
      # Your custom packages and modifications
      overlays = import ./overlays;
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # Devshell for bootstrapping
      # Accessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { };
      });
      # This instantiates nixpkgs for each system listed above
      # Allowing you to add overlays and configure it (e.g. allowUnfree)
      # Our configurations will use these instances
      # Your flake will also let you access your package set through nix build, shell, run, etc.
      legacyPackages = forAllSystems (system:
        import inputs.nixpkgs {
          inherit system;
          # This adds our overlays to pkgs
          overlays = builtins.attrValues overlays;

          # NOTE: Using `nixpkgs.config` in your NixOS config won't work
          # Instead, you should set nixpkgs configs here
          # (https://nixos.org/manual/nixpkgs/stable/#idm140737322551056)
          config.allowUnfree = true;
        });
      packages = forAllSystems
        (system: import ./pkgs { pkgs = legacyPackages.${system}; });

      nixosConfigurations = {
        cobalto = nixpkgs.lib.nixosSystem {
          pkgs = legacyPackages."x86_64-linux";
          modules = [
            ./hosts/cobalto/configuration.nix

          ] ++ (builtins.attrValues nixosModules);
          specialArgs = { inherit inputs outputs; };
        };

        amatista = nixpkgs.lib.nixosSystem {
          pkgs = legacyPackages."x86_64-linux";
          modules = [ ./hosts/amatista/configuration.nix ]
            ++ (builtins.attrValues nixosModules);
          specialArgs = { inherit inputs outputs; };
        };
      };
      darwinConfigurations = {
        lazulita = darwin.lib.darwinSystem {
          pkgs = legacyPackages."aarch64-darwin";
          modules = [ ./hosts/lazulita/configuration.nix ]
            ++ (builtins.attrValues darwinModules);

          specialArgs = { inherit inputs outputs; };

        };
      };
      nixOnDroidConfigurations = {
        indigo = nix-on-droid.lib.nixOnDroidConfiguration {
      modules = [ ./hosts/indigo ]

            ++ (builtins.attrValues darwinModules);

          specialArgs = { inherit inputs outputs; };
      };};


      homeConfigurations = {
        # FIXME replace with your username@hostname
        "diego@cobalto" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = {
            inherit inputs outputs;
          }; # Pass flake inputs to our config
          modules = (builtins.attrValues homeManagerModules) ++ [
            # > Our main home-manager configuration file <
            ./home/diego/cobalto.nix
          ];
        };

        "diego@amatista" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = {
            inherit inputs outputs;
          }; # Pass flake inputs to our config
          modules = (builtins.attrValues homeManagerModules) ++ [
            # > Our main home-manager configuration file <
            ./home/diego/amatista.nix
          ];
        };

        "diego@lazulita" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."aarch64-darwin";
          extraSpecialArgs = {
            inherit inputs outputs;
          }; # Pass flake inputs to our config
          modules = (builtins.attrValues homeManagerModules) ++ [
            # > Our main home-manager configuration file <
            ./home/diego/lazulita.nix
          ];
        };

      };
    };
}
