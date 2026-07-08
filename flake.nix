{
  description = "My personal nix config";
  inputs = {

    hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";

    stylix.url = "github:danth/stylix";

    # NixVirt for declarative libvirt VM definitions
    nixvirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CodeRabbit CLI (AI code review)
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agent skills for Obsidian (kepano/obsidian-skills). Consumed as raw
    # SKILL.md files via programs.ai-skills.extraSkillSources, so flake=false.
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };

    # Reusable AI/agent tooling modules (extracted from this repo)
    ai-tooling = {
      url = "github:DiegoBarrosA/nix-ai-tooling";
    };

    # Private local config (not pushed to github)
    clin.url = "github:reekta92/clin-rs";

    private-config = {
      # TEMP: pinned to the in-flight cleanup branch (this nix-config branch
      # consumes the neutral work* exports, which don't exist on
      # private-config master yet). Drop ?ref when both cleanup branches
      # merge.
      url = "git+ssh://git@github.com/DiegoBarrosA/nix-private-config.git?ref=employer-cleanup";
      flake = true;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      inherit (inputs.nixpkgs.lib) filterAttrs traceVal;
      inherit (builtins) mapAttrs elem;
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;
      homeModules = import ./modules/home-manager // {
        inherit (inputs.ai-tooling.homeManagerModules)
          mcp-config opencode-config claude-code-config
          cursor-config antigravity-config ai-skills;
      };
      devShells = forAllSystems (system: {
        default = inputs.nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { };
      });
      legacyPackages = forAllSystems (
        system:
        import inputs.nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
            permittedInsecurePackages = [
              "olm-3.2.16" # Required by maubot for E2EE
              "pypy2.7-setuptools-44.0.0" # Pulled in via python3 evaluation chain
              "pypy2.7-pip-20.3.4" # Pulled in via python3 evaluation chain
            ];
          };
        }
      );
      packages = forAllSystems (
        system:
        let
          pkgs = legacyPackages.${system};
          lib = inputs.nixpkgs.lib;
          privatePackages = inputs.private-config.packages.${system} or { };
        in
        import ./pkgs { inherit pkgs lib privatePackages; }
        // {
          clin = inputs.clin.packages.${system}.default;
          coderabbit-cli = inputs.llm-agents.packages.${system}.coderabbit-cli;
        }
      );
      myLib = import ./lib {
        inherit
          inputs
          self
          legacyPackages
          packages
          homeModules
          nixosModules
          ;
      };
      nixosConfigurations = {
        cobalto = myLib.mkHost "x86_64-linux" "cobalto" { };
        granate = myLib.mkHost "x86_64-linux" "granate" { };
        rubi = myLib.mkHost "x86_64-linux" "rubi" { desktop = "sway"; };
      };

      # Deploy-rs configuration
      deploy = {
        nodes = {
          cobalto = {
            hostname = "cobalto"; # Use Tailscale hostname
            fastConnection = false;
            remoteBuild = false; # Build locally, then copy to remote
            magicRollback = false; # network (tailscaled) restarts mid-activation sever the confirm SSH
            autoRollback = false;
            profiles = {
              system = {
                sshUser = "root";
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.cobalto;
                user = "root";
              };
            };
          };
          granate = {
            hostname = "204.168.253.49";
            fastConnection = true;
            remoteBuild = true;
            magicRollback = false; # network restarts mid-activation sever the confirm SSH
            autoRollback = false;
            profiles = {
              system = {
                sshUser = "root";
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.granate;
                user = "root";
              };
            };
          };
        };
      };

      # Deploy-rs checks disabled due to platform conflicts
      # This will now work if uncommented, because 'self' is defined
      # checks.x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks self.deploy;

      # Expose deploy-rs as an app (--skip-checks avoids warnings about non-standard outputs)
      apps = forAllSystems (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          deploy-rs = inputs.deploy-rs.packages.${system}.deploy-rs;
        in
        {
          deploy = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "deploy" ''
                exec ${deploy-rs}/bin/deploy-rs --skip-checks "$@"
              ''
            );
            meta = {
              description = "Deploy NixOS configurations to remote hosts";
            };
          };
        }
      );

      # --- MOVE homeConfigurations TO TOP LEVEL ---
      homeConfigurations = {
        "diego@cobalto" = myLib.mkHome "x86_64-linux" ./home/diego/cobalto.nix [ ];
        "diego@rubi" = myLib.mkHome "x86_64-linux" ./home/diego/rubi.nix [
          inputs.private-config.homeManagerModules.workExtras
        ];
        "diego@lapislazuli" = myLib.mkHome "aarch64-darwin" ./home/diego/lapislazuli.nix [ ];
      };

      # Nix-on-Droid configurations (Android)
      nixOnDroidConfigurations = {
        lonsdaleita = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "aarch64-linux";
            overlays = builtins.attrValues overlays ++ [
              inputs.nix-on-droid.overlays.default
            ];
            config = {
              allowUnfree = true;
            };
          };
          extraSpecialArgs = {
            inherit inputs;
            inherit (inputs) nix-colors;
            customPkgs = packages."aarch64-linux";
          };
          home-manager-path = inputs.home-manager.outPath;
          modules = [ ./hosts/lonsdaleita ];
        };
      };

      # MODIFICATION 3: Added the missing 'in' block to return the outputs
    in
    {
      inherit
        overlays
        devShells
        legacyPackages
        packages
        nixosConfigurations
        homeConfigurations
        apps
        ;

      # Non-standard outputs (will show warnings but work correctly)
      # deploy-rs expects this exact structure
      inherit deploy;

      # nix-on-droid expects this exact name
      inherit nixOnDroidConfigurations;
    };
}
