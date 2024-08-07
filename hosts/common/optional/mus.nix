{ config, lib, pkgs, inputs, ... }: {
  imports = [ inputs.musnix.nixosModules.musnix ];
  musnix = {
    enable = true;
    das_watchdog.enable = true;
  };
  environment.systemPackages = with pkgs; [
    ##Plugins
    ##LV2
    aether-lv2
    ams-lv2
    artyFX
    boops
    bschaffl
    bsequencer
    bshapr
    cardinal
    distrho
    drumgizmo
    eq10q
    fmsynth
    fomp
    fverb
    gxmatcheq-lv2
    gxplugins-lv2
    infamousPlugins
    kapitonov-plugins-pack
    magnetophonDSP.CharacterCompressor
    magnetophonDSP.LazyLimiter
    magnetophonDSP.MBdistortion
    magnetophonDSP.RhythmDelay
    mda_lv2
    metersLv2
    mod-distortion
    mooSpace
    ninjas2
    noise-repellent
    plujain-ramp
    rkrlv2
    sfizz
    speech-denoiser
    swh_lv2
    talentedhack
    tunefish
    airwindows-lv2
    ##LADSPA
    AMB-plugins
    FIL-plugins
    autotalent
    caps
    ladspaPlugins
    lsp-plugins
    nova-filters
    tap-plugins
    zam-plugins
    calf
    ##utilities
    ardour
    zyn-fusion
    carla
    hydrogen
    tenacity
    renoise-latest
  ];
}
