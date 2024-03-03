{
  description = "My personal nix config";
  inputs = {
    hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    musnix.url = "github:musnix/musnix";
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #TODO: 
    nix-on-droid = {
      url = "github:t184256/nix-on-droid/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    hyprland.url = "github:hyprwm/hyprland/v0.20.1beta";
    hyprwm-contrib.url = "github:hyprwm/contrib";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
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
  outputs = { self, nixpkgs, darwin, nix-on-droid, home-manager
    , nixpkgs-firefox-darwin, nix-doom-emacs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs.lib) filterAttrs traceVal;
      inherit (builtins) mapAttrs elem;
      supportedSystems = [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in rec {
      overlays = import ./overlays;
      nixosModules = import ./modules/nixos;
      darwinModules = import ./modules/darwin;
      nixOnDroidModules = import ./modules/nix-on-droid;
      homeManagerModules = import ./modules/home-manager;
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { };
      });
      legacyPackages = forAllSystems (system:
        import inputs.nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config.allowUnfree = true;
        });
      packages = forAllSystems
        (system: import ./pkgs { pkgs = legacyPackages.${system}; });
      nixosConfigurations = let
        mkHost = system: hostname:
          nixpkgs.lib.nixosSystem {
            pkgs = legacyPackages.${system};
            modules = [ ./hosts/${hostname} ]
              ++ (builtins.attrValues nixosModules);
            specialArgs = { inherit inputs outputs; };
          };
      in {
        cobalto = mkHost "x86_64-linux" "cobalto";
        amatista = mkHost "x86_64-linux" "amatista";
      };
      darwinConfigurations = let
        mkHost = system: hostname:
          darwin.lib.darwinSystem {
            pkgs = legacyPackages.${system};
            modules = [
              { nixpkgs.overlays = [ inputs.nixpkgs-firefox-darwin.overlay ]; }
              ./hosts/${hostname}
            ] ++ (builtins.attrValues darwinModules);
            specialArgs = { inherit inputs outputs; };
          };
      in { lazulita = mkHost "aarch64-darwin" "lazulita"; };

      nixOnDroidConfigurations = let
        mkHost = system: hostname:
          nix-on-droid.lib.nixOnDroidConfiguration {
            pkgs = legacyPackages.${system};
            modules = [ ./hosts/${hostname} ];
          };
      in { indigo = mkHost "aarch64-linux" "indigo"; };
      homeConfigurations = {
        "diego@cobalto" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = (builtins.attrValues homeManagerModules)
            ++ [ ./home/diego/cobalto.nix ];
        };
        "diego@amatista" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = (builtins.attrValues homeManagerModules)
            ++ [ ./home/diego/amatista.nix ];
        };
        "diego@lazulita" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."aarch64-darwin";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = (builtins.attrValues homeManagerModules)
            ++ [ ./home/diego/lazulita.nix ];
        };
        "diego@indigo" = home-manager.lib.homeManagerConfiguration {
          pkgs = legacyPackages."aarch64-linux";
          extraSpecialArgs = { inherit inputs outputs; };
          modules = (builtins.attrValues homeManagerModules)
            ++ [ ./home/diego/indigo.nix ];
        };
      };
    };
}
