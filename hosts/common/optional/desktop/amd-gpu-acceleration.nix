{ config, lib, pkgs, ... }:

{
  # AMD Radeon GPU Configuration for Hardware Acceleration
  # Optimized for Jellyfin media encoding and LLM inference (RX 460 / Polaris11)
  
  # Hardware acceleration configuration
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # VAAPI drivers for hardware video acceleration
  libva-vdpau-driver
        # libvdpau-va-gl  # Temporarily disabled due to CMake build issues
        
        # AMD ROCm packages for compute workloads
        rocmPackages.rocm-runtime
        rocmPackages.rocm-device-libs
        rocmPackages.rocm-smi
        rocmPackages.hipify
        rocmPackages.clr
        
        # Mesa drivers (using newer mesa instead of deprecated mesa.drivers)
        # mesa.drivers  # Deprecated, using default mesa
        
        # Additional codec support
        intel-media-driver  # For broad compatibility
      ];
      
      # extraPackages32 disabled - pkgsi686Linux evaluation is broken with current nixpkgs
      # (missing i686-linux hashes for python and other packages)
      # 32-bit hardware video acceleration is rarely needed in practice
    };

    # Enable AMD GPU
    amdgpu = {
      opencl.enable = true;
    };
  };

  # Boot configuration for AMD GPU
  boot = {
    # Enable early KMS for AMD
    initrd.kernelModules = [ "amdgpu" ];
    
    kernelModules = [ 
      "amdgpu" 
      "kvm-amd"
    ];
    
    kernelParams = [
      # AMD GPU specific parameters
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "radeon.si_support=0"
      "radeon.cik_support=0"
      
      # Enable GPU scheduling for better performance
      "amdgpu.gpu_recovery=1"
      "amdgpu.hw_i2c=1"
      
      # Memory management
      "amdgpu.vm_fragment_size=9"
    ];
    
    # Blacklist radeon driver to ensure amdgpu is used
    blacklistedKernelModules = [ "radeon" ];
  };

  # Environment variables for GPU acceleration
  environment = {
    variables = {
      # VAAPI driver selection
      LIBVA_DRIVER_NAME = "radeonsi";
      
      # ROCm configuration for GCN 4.0 (RX 460 / Polaris11)
      HSA_OVERRIDE_GFX_VERSION = "8.0.3";
      ROCM_PATH = "${pkgs.rocmPackages.clr}";
      
      # Mesa configuration
      MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
      
      # GPU memory management
      AMD_VULKAN_ICD = "RADV";
    };

    systemPackages = with pkgs; [
      # GPU monitoring and management tools
      radeontop
      clinfo
      vulkan-tools
      mesa-demos
      
      # Video acceleration utilities
      libva-utils
      vdpauinfo
      
      # ROCm tools
      rocmPackages.rocminfo
      rocmPackages.rocm-smi
      
      # FFmpeg with hardware acceleration support
      (ffmpeg.override {
        withVaapi = true;
        withVdpau = true;
        withVulkan = true;
      })
    ];
  };

  # Udev rules for proper GPU device permissions
  services.udev.extraRules = ''
    # AMD GPU devices
    KERNEL=="renderD*", GROUP="render", MODE="0666"
    KERNEL=="card*", GROUP="video", MODE="0666"
    
    # ROCm devices
    KERNEL=="kfd", GROUP="render", MODE="0666"
    
    # DRM devices
    KERNEL=="controlD*", GROUP="video", MODE="0666"
  '';

  # Groups for GPU access
  users.groups = {
    render = {};
    video = {};
  };

  # Add users to GPU groups
  users.users.diego.extraGroups = [ "video" "render" ];

  # Systemd service for GPU initialization and monitoring
  systemd.services.gpu-setup = {
    description = "AMD GPU Setup and Monitoring";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman.service" "podman-jellyfin.service" ];
    after = [ "systemd-udev-settle.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 60;
    };
    
    script = ''
      # Wait for GPU devices to be available
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
      
      # Set GPU power profile for optimal performance
      if [ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
        echo "auto" > /sys/class/drm/card0/device/power_dpm_force_performance_level
      fi
      
      # Enable GPU recovery
      if [ -f /sys/class/drm/card0/device/gpu_recovery ]; then
        echo "1" > /sys/class/drm/card0/device/gpu_recovery
      fi
      
      # Log GPU information
      ${pkgs.rocmPackages.rocminfo}/bin/rocminfo > /var/log/gpu-info.log 2>&1 || true
      ${pkgs.libva-utils}/bin/vainfo > /var/log/vaapi-info.log 2>&1 || true
      ${pkgs.vdpauinfo}/bin/vdpauinfo > /var/log/vdpau-info.log 2>&1 || true
      
      echo "GPU setup completed successfully"
    '';
  };

  # Configure Jellyfin for hardware acceleration (disabled - using containerized jellyfin)
  # services.jellyfin = {
  #   enable = true;
  #   user = "diego";
  #   group = "video";
  #   openFirewall = true;
  # };

  # Systemd service override for Jellyfin to ensure GPU access (disabled - using containerized jellyfin)
  # systemd.services.jellyfin = {
  #   serviceConfig = {
  #     # Add supplementary groups for GPU access
  #     SupplementaryGroups = [ "video" "render" ];
  #     
  #     # Device access
  #     DeviceAllow = [
  #       "/dev/dri/renderD128 rw"
  #       "/dev/dri/card0 rw"
  #     ];
  #     
  #     # Private devices = false to allow GPU access
  #     PrivateDevices = false;
  #   };
  # };

  # Performance tuning for GPU workloads
  systemd.services.gpu-performance = {
    description = "GPU Performance Tuning";
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Set GPU memory clock for better performance (if available)
      if [ -f /sys/class/drm/card0/device/pp_mclk_od ]; then
        echo "0" > /sys/class/drm/card0/device/pp_mclk_od
      fi
      
      # Set GPU core clock for better performance (if available)
      if [ -f /sys/class/drm/card0/device/pp_sclk_od ]; then
        echo "0" > /sys/class/drm/card0/device/pp_sclk_od
      fi
    '';
  };

  # Firewall exception for GPU services
  networking.firewall = {
    allowedTCPPorts = [
      # ROCm debugging (if needed)
      # 8080
    ];
  };

  # Log rotation for GPU logs
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