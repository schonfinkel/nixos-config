{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.commons;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.commons = {
    enable = mkEnableOption "Enable/Disable common services and packages";

    hostName = mkOption {
      type = lib.types.str;
    };

    timeZone = mkOption {
      type = lib.types.str;
      default = "America/Cuiaba";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      # Default system packages
      environment.systemPackages = with pkgs; [
        brightnessctl
        glib
        networkmanagerapplet
        tree
      ];

      # Select internationalisation properties.
      console.useXkbConfig = true;

      # Set your time zone.
      time.timeZone = cfg.timeZone;

      services.journald.extraConfig = ''
        MaxRetentionSec=14day
      '';

      # For udiskie
      services.udisks2.enable = true;

      # Networking
      networking.hostName = cfg.hostName;
      # networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

      # Pick only one of the below networking options.
      # Enables wireless support via wpa_supplicant.
      # networking.wireless.enable = true;

      # Easiest to use and most distros use this by default.
      networking.networkmanager.enable = true;

    })
  ]);
}
