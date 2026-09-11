{
  description = "My personal nix config";
  inputs = {

    hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vital-presets = {
      url = "github:Miserlou/VitalPresets";
      flake = false;
    };

    firefox-userchrome = {
      url = "github:DiegoBarrosA/firefox-qutebrowser-userchrome";
      flake = false;
    };

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

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };

    ai-tooling = {
      url = "github:DiegoBarrosA/nix-ai-tooling";
    };

    clin.url = "github:reekta92/clin-rs";

    private-config = {

      url = "git+ssh://git@github.com/DiegoBarrosA/nix-private-config.git?ref=employer-cleanup";
      flake = true;
    };

    zennotes = {
      url = "github:ZenNotes/zennotes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ekphos = {
      url = "github:hanebox/ekphos";
      flake = false;
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    teams-calls-fetcher = {
      url = "github:DiegoBarrosA/teams-calls-fetcher";
    };

    mixbus-source = {
      url = "path:/home/diego/Downloads/Mixbus-12.0.1-x86_64.tar";
      flake = false;
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
          mcp-config
          opencode-config
          jcode-config
          claude-code-config
          claude-desktop-config
          cursor-config
          antigravity-config
          ai-skills
          ai-system-prompt
          happier-config
          ;
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
              "olm-3.2.16"
              "pypy2.7-setuptools-44.0.0"
              "pypy2.7-pip-20.3.4"
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
        import ./pkgs { inherit pkgs lib privatePackages; mixbus-source = inputs.mixbus-source; }
        // {
          clin = inputs.clin.packages.${system}.default;
          coderabbit-cli = inputs.llm-agents.packages.${system}.coderabbit-cli;
          zennotes-server = inputs.zennotes.packages.${system}.zennotes-server;
          ekphos = pkgs.callPackage ./pkgs/ekphos { src = inputs.ekphos; };
          teams-calls-fetcher = inputs.teams-calls-fetcher.packages.${system}.default;
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
      theme = {
        scheme = "material-darker";
        mode = "dark";
      };

      nixosConfigurations = {
        cobalto = myLib.mkHost "x86_64-linux" "cobalto" { inherit theme; };
        rubi = myLib.mkHost "x86_64-linux" "rubi" { desktop = "sway"; };
      };

      deploy = {
        nodes = {
          cobalto = {
            hostname = "cobalto";
            fastConnection = false;
            remoteBuild = true;
            magicRollback = false;
            autoRollback = false;
            profiles = {
              system = {
                sshUser = "root";
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.cobalto;
                user = "root";
              };
            };
          };
        };
      };

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
                exec ${deploy-rs}/bin/deploy --skip-checks "$@"
              ''
            );
            meta = {
              description = "Deploy NixOS configurations to remote hosts";
            };
          };
        }
      );

      homeConfigurations = {
        "diego@cobalto" = myLib.mkHome "x86_64-linux" ./home/diego/cobalto.nix [ ] { inherit theme; };
        "diego@rubi" = myLib.mkHome "x86_64-linux" ./home/diego/rubi.nix [
          inputs.private-config.homeManagerModules.workExtras
          inputs.private-config.homeManagerModules.workClaudeDesktopMcpConfig
        ] { desktop = "sway"; };
      };

      nixOnDroidConfigurations = {
        infinix = myLib.mkNixOnDroid "infinix";
      };

    in
    {
      inherit
        overlays
        devShells
        legacyPackages
        packages
        nixosConfigurations
        homeConfigurations
        nixOnDroidConfigurations
        apps
        ;

      inherit deploy;
    };
}
