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
      imv
      mpv
      ncmpcpp
      graphviz
      feedr

      # For reading pdfs
      sioyek
      libnotify
    ];

    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;

      settings = {
        mgr = {
          show_hidden = false;
          show_symlink = true;
        };

        opener = {
          # Define the custom openers
          pdf_reader = [
            { 
              run = ''sioyek "$@"''; 
              block = false; 
              detach = true; 
              desc = "Sioyek"; 
            }
          ];
          image_viewer = [
            { run = ''imv "$@"''; detach = true; desc = "imv"; }
          ];
          video_player = [
            { run = ''mpv "$@"''; detach = true; desc = "mpv"; }
          ];
        };

        open = {
          rules = [
            # Link file patterns to the openers defined above
            { mime = "application/pdf"; use = "pdf_reader"; }
            { name = "*.pdf"; use = "pdf_reader"; }
            { mime = "image/*"; use = "image_viewer"; }
            { mime = "video/*"; use = "video_player"; }
          ];
        };
      };
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
