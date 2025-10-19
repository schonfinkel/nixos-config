{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.audio;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.audio = {
    enable = mkEnableOption "Enable/Disable common services and packages";
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
