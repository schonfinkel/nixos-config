{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.themes;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;

  defaultWallpaper = ../wallpapers/wallpaper.png;
in
{
  options.hostModules.themes = {
    enable = mkEnableOption "Enable/Disable common services and packages";

    cursorSize = mkOption {
      type = lib.types.int;
      default = 24;
    };

    opacity = mkOption {
      type = lib.types.float;
      default = 0.9;
    };

    wallpaperPath = mkOption {
      type = lib.types.path;
      default = defaultWallpaper;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({

      stylix = {
        enable = true;
        image = cfg.wallpaperPath;
        polarity = "dark";
        opacity.terminal = cfg.opacity;
        cursor.package = pkgs.bibata-cursors;
        cursor.name = "Bibata-Modern-Ice";
        cursor.size = cfg.cursorSize;
        fonts = {
          sizes = {
            applications = 16;
            terminal = 16;
            desktop = 14;
            popups = 12;
          };
        };
      };

    })
  ]);
}
