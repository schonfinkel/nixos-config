{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.media;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.media = {
    enable = mkEnableOption "Enable a file manager and other applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mpv
      ncmpcpp
      graphviz

      # atool
      # ffmpeg
      # ffmpegthumbnailer
      # highlight
      # mediainfo
      # poppler-utils
      # zathura
    ];

    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      shellWrapperName = "y";

      settings = {
        mgr = {
          show_hidden = false;
          show_symlink = true;
        };
      };
    };

    programs.newsboat = {
      enable = true;
    };

    xdg.configFile = {
      mpv = {
        source = ../dotfiles/mpv;
        recursive = true;
      };
      zathura = {
        source = ../dotfiles/zathura;
        recursive = true;
      };
    };
  };
}
