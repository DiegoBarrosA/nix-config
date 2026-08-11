{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libva-vdpau-driver
        rocmPackages.rocm-runtime
        rocmPackages.rocm-device-libs
        rocmPackages.rocm-smi
        rocmPackages.hipify
        rocmPackages.clr
        intel-media-driver
      ];
    };
    amdgpu = {
      opencl.enable = true;
    };
  };
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [
      "amdgpu"
      "kvm-amd"
    ];

    kernelParams = [
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "radeon.si_support=0"
      "radeon.cik_support=0"
      "amdgpu.gpu_recovery=1"
      "amdgpu.hw_i2c=1"
      "amdgpu.vm_fragment_size=9"
    ];
    blacklistedKernelModules = [ "radeon" ];
  };
  environment = {
    variables = {
      LIBVA_DRIVER_NAME = "radeonsi";
      HSA_OVERRIDE_GFX_VERSION = "8.0.3";
      ROCM_PATH = "${pkgs.rocmPackages.clr}";
      MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
      AMD_VULKAN_ICD = "RADV";
    };

    systemPackages = with pkgs; [
      radeontop
      clinfo
      vulkan-tools
      mesa-demos
      libva-utils
      vdpauinfo
      rocmPackages.rocminfo
      rocmPackages.rocm-smi
      (ffmpeg.override {
        withVaapi = true;
        withVdpau = true;
        withVulkan = true;
      })
    ];
  };

  services.udev.extraRules = ''
    # AMD GPU devices
    KERNEL=="renderD*", GROUP="render", MODE="0666"
    KERNEL=="card*", GROUP="video", MODE="0666"
    # ROCm devices
    KERNEL=="kfd", GROUP="render", MODE="0666"
    # DRM devices
    KERNEL=="controlD*", GROUP="video", MODE="0666"
  '';
  users.groups = {
    render = { };
    video = { };
  };
  users.users.diego.extraGroups = [
    "video"
    "render"
  ];

  systemd.services.gpu-setup = {
    description = "AMD GPU Setup and Monitoring";
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman.service"
      "podman-jellyfin.service"
    ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 60;
    };

    script = ''
      timeout=30
      while [ $timeout -gt 0 ]; do
        if [ -e /dev/dri/card0 ] && [ -e /dev/dri/renderD128 ]; then
          echo "GPU devices found"
          break
        fi
        echo "Waiting for GPU devices... ($timeout seconds remaining)"
        sleep 1
        timeout=$((timeout - 1))
      done
      if [ ! -e /dev/dri/card0 ]; then
        echo "Warning: /dev/dri/card0 not found"
        ls -la /dev/dri/ || echo "No /dev/dri directory"
      fi
      if [ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
        echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level
      fi
      if [ -f /sys/class/drm/card0/device/gpu_recovery ]; then
        echo "1" > /sys/class/drm/card0/device/gpu_recovery
      fi
      ${pkgs.rocmPackages.rocminfo}/bin/rocminfo > /var/log/gpu-info.log 2>&1 || true
      ${pkgs.libva-utils}/bin/vainfo > /var/log/vaapi-info.log 2>&1 || true
      ${pkgs.vdpauinfo}/bin/vdpauinfo > /var/log/vdpau-info.log 2>&1 || true
      echo "GPU setup completed successfully"
    '';
  };
  systemd.services.gpu-performance = {
    description = "GPU Performance Tuning";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ -f /sys/class/drm/card0/device/pp_mclk_od ]; then
        echo "0" > /sys/class/drm/card0/device/pp_mclk_od
      fi
      if [ -f /sys/class/drm/card0/device/pp_sclk_od ]; then
        echo "0" > /sys/class/drm/card0/device/pp_sclk_od
      fi
    '';
  };
  services.logrotate.settings = {
    "/var/log/gpu-*.log" = {
      rotate = 5;
      weekly = true;
      missingok = true;
      notifempty = true;
      compress = true;
    };
  };
}
