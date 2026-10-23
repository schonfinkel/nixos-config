{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.gaming;
  impermanenceCfg = config.hostModules.impermanence;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.gaming = {
    enable = mkEnableOption "Enable/Disable gaming services and packages";

    hostName = mkOption {
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # https://wiki.nixos.org/wiki/Steam/en
      programs.steam = {
        enable = true;
        # https://wiki.nixos.org/wiki/Steam/en#Proton
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };

      # https://wiki.nixos.org/wiki/Steam/en#Troubleshooting
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      environment.systemPackages = with pkgs; [
        vulkan-tools
      ];
    }

    # Steam keeps its library, compatdata and config in:
    # - ~/.local/share/Steam
    # - ~/.steam
    # Without this, impermanent hosts lose every installed game on reboot. 
    (mkIf impermanenceCfg.enable {
      environment.persistence."${impermanenceCfg.persistDirectory}".users."${impermanenceCfg.username
      }".directories =
        builtins.filter (d: !(builtins.elem d impermanenceCfg.dataUserDirectories)) [
          ".local/share/Steam"
          ".steam"
        ];
    })
  ]);
}
