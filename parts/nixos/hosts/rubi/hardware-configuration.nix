{ ... }:
{
  flake.modules.nixos.rubi-hardware-configuration = {
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "tpm_tis"
    "tpm_crb"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  hardware.amdgpu.initrd.enable = true;

  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [
    "-19"
    "-T0"
  ];

  disko.devices = {
    disk = {
      rubi = {
        type = "disk";

        device = "/dev/disk/by-id/nvme-KINGSTON_SNV2S1000G_50026B778548EA82";
        content = {
          type = "gpt";
          partitions = {

            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "rubi-root";
                settings = {
                  allowDiscards = true;

                  crypttabExtraOpts = [
                    "tpm2-device=auto"
                    "fido2-device=auto"
                  ];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {

                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    "/root-blank" = {
                      mountpoint = "/.root-blank";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    "/persist" = {
                      mountpoint = "/nix/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };

                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "16G";
                      };
                    };
                  };
                  mountpoint = "/partition-root";
                };
              };
            };
          };
        };
      };
    };
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-tools
    ];
  };
};
}
