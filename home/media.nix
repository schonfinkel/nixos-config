{
  config,
  lib,
  pkgs,
  ...
}:

let
  module_name = "homeModules.media";
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
      enable = mkEnableOption "Enable a file manager and other applications";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mpv
      ncmpcpp
      graphviz
    ];

    programs.ranger = {
      enable = true;
      aliases = {
        e = "edit";
        q = "quit";
        qa = "quitall";
        "q!" = "quit!";
        f = "console fzf_filter%space";
      };
      settings = {
        preview_images = true;
        preview_images_method = "kitty";
        preview_files = true;
        preview_directories = true;
        vcs_aware = true;
        viewmode = "miller";
        draw_borders = "both";
        mouse_enabled = true;
        update_title = true;
        padding_right = false;
      };
      rifle = [
        {
          condition = "mime ^image";
          command = ''${pkgs.nsxiv}/bin/nsxiv -- "$@"'';
        }
        {
          condition = "mime ^text, has nvim";
          command = ''nvim -nw -- "$@"'';
        }
        {
          condition = "ext pdf|djvu|epub, has zathura";
          command = ''zathura -- "$@"'';
        }
        {
          condition = "mime ^video|^audio, has mpv, X, flag f";
          command = ''${pkgs.mpv}/bin/mpv -- "$@"'';
        }
      ];
      extraPackages = with pkgs; [
        atool
        ffmpeg
        ffmpegthumbnailer
        highlight
        mediainfo
        poppler_utils
        zathura
      ];
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
