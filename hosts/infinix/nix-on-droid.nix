{
  pkgs,
  lib,
  inputs,
  nix-colors,
  ...
}:
{
  system.stateVersion = "24.05";

  # Phone LLM server: llama.cpp (llama-server) with Vulkan + CPU backends,
  # plus tooling for model downloads, git, and SSH (client + server).
  environment.packages = [
    pkgs.llama-cpp-vulkan
    pkgs.curl
    pkgs.jq
    pkgs.git
    pkgs.ripgrep
    pkgs.openssh
  ];

  home-manager.sharedModules = [
    # `colorscheme` option used by helix/zellij theming (see modules/home-manager/colors.nix)
    ../../modules/home-manager/colors.nix
  ];

  # Pass repo inputs down into the home-manager submodule system (used by the
  # colors module and the shared global/cli configs). `isNixOnDroid` lets the
  # shared configs detect the phone (their pkgs are aarch64-linux, not
  # aarch64-android, so hostPlatform.isAndroid can't).
  home-manager.extraSpecialArgs = {
    inherit inputs nix-colors;
    isNixOnDroid = true;
  };

  # Use the flake's pkgs (allowUnfree + repo overlays) instead of letting
  # home-manager evaluate its own nixpkgs, which refuses unfree packages.
  home-manager.useGlobalPkgs = true;

  # Home-manager config. Reuses the shared CLI feature set (platform-guarded,
  # so desktop-only packages are skipped on Android) and the shared global base.
  home-manager.config =
    { pkgs, lib, ... }:
    let
      serverScript = pkgs.writeShellScriptBin "phone-llm-server" ''
        set -e
        : ''${MODEL_FILE:="$HOME/models/qwen3-8b-instruct-q4_k_m.gguf"}
        : ''${LLM_HOST:="0.0.0.0"}
        : ''${LLM_PORT:="8080"}
        : ''${LLM_CTX:="8192"}
        : ''${LLM_THREADS:="4"}

        if [ ! -f "$MODEL_FILE" ]; then
          echo "model not found: $MODEL_FILE" >&2
          echo "put a GGUF under $HOME/models/ or set MODEL_FILE" >&2
          exit 1
        fi

        exec llama-server \
          -m "$MODEL_FILE" \
          -c "$LLM_CTX" \
          -t "$LLM_THREADS" \
          --host "$LLM_HOST" \
          --port "$LLM_PORT" \
          "$@"
      '';

      # SSH server for the phone. Start it in a session, like the LLM server:
      #   phone-sshd
      # Then from the laptop: ssh infinix (LAN) or ssh infinix-usb (adb reverse).
      sshdScript = pkgs.writeShellScriptBin "phone-sshd" ''
        set -e
        : ''${SSHD_PORT:="8022"}
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        if [ ! -f "$HOME/.ssh/ssh_host_ed25519_key" ]; then
          echo "generating ssh host key..." >&2
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/ssh_host_ed25519_key" -N "" >&2
        fi
        chmod 600 "$HOME/.ssh/ssh_host_ed25519_key"
        exec ${pkgs.openssh}/bin/sshd -D -e -p "$SSHD_PORT" -f "$HOME/.ssh/sshd_config"
      '';

      # Inbound SSH keys. Same set as hosts/common/global/openssh.nix for NixOS hosts.
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXblym20SD75es2z5Qay0mfW+g2zvKPBVMsUFakIyBK diegobarrosaraya@outlook.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpXSRXYbg97jxtfnnitIgNQLvGnLgZBWE9079qD2U4C diego@lazulita"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBM2hEBu4cWTnBMbGdu2bG+sAZu5kBMtc75NFhShmX21"
      ];
    in
    {
      imports = [
        ../../home/diego/global
        ../../home/diego/features/cli
      ];

      home.packages = [ serverScript sshdScript ];
      home.stateVersion = "26.05";
      # nix-on-droid doesn't ship systemd; don't attempt to start user services.
      systemd.user.startServices = false;

      home.sessionVariables = {
        LLM_HOST = "0.0.0.0";
        LLM_PORT = "8080";
      };

      programs.bash.enable = true;
      programs.bash.shellAliases = {
        llm-bench-cpu = "llama-bench -m $HOME/models/qwen3-8b-instruct-q4_k_m.gguf -t 4 -p 512 -n 128";
        llm-bench-gpu = "llama-bench -m $HOME/models/qwen3-8b-instruct-q4_k_m.gguf -ngl 99 -p 512 -n 128";
      };

      home.file = {
        # Allow SSH into the phone (user: nix-on-droid).
        ".ssh/authorized_keys".text = (lib.concatStringsSep "\n" authorizedKeys) + "\n";
        # sshd config. %h expands to the user home (the nix-on-droid app data dir).
        ".ssh/sshd_config".text = ''
          # Managed by home-manager (hosts/infinix/nix-on-droid.nix).
          Port 8022
          PasswordAuthentication no
          PermitRootLogin no
          PubkeyAuthentication yes
          UsePAM no
          StrictModes no
          AllowUsers nix-on-droid

          HostKey %h/.ssh/ssh_host_ed25519_key
          PidFile %h/.ssh/sshd.pid
          AuthorizedKeysFile %h/.ssh/authorized_keys

          LogLevel VERBOSE
        '';
      };

      # features/cli/ssh.nix assumes the laptop's GitHub key layout and an
      # omnistation fragment from private-config; adapt both for the phone.
      programs.ssh = {
        includes = lib.mkForce [ ];
        settings."github.com" = {
          HostName = "ssh.github.com";
          Port = 443;
          IdentityFile = lib.mkForce "~/.ssh/id_ed25519";
        };
      };
    };
}
