{
  config,
  lib,
  pkgs,
  ...
}:

let
  module_name = "modules.hostModules.audio";
  cfg = config."${module_name}";
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options = {
    "${module_name}" = {
      enable = mkEnableOption "Enable/Disable common services and packages";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({

      environment.systemPackages = with pkgs; [
        flac
        pavucontrol
      ];

      # Enable sound.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };

    })
  ]);
}
