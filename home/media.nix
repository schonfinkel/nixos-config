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
      libnotify
    ];

    programs.sioyek = {
      enable = true;
	    bindings = {
	      "fit_to_page_width" = "<f9>";
	      "fit_to_page_width_smart" = "<f10>";
	      "move_up" = "k";
	      "move_down" = "j";
	      "move_left" = "h";
	      "move_right" = "l";
	      "screen_down" = "d";
	      "screen_up" = "u";
	      "toggle_fullscreen" = "f";
	      "toggle_highlight" = "H";
	      "toggle_dark_mode" = "i";
	      "toggle_presentation_mode" = "<f5>";
	      "toggle_statusbar" = "S";
          "zoom_in" = "K";
          "zoom_out" = "J";
	      "quit" = "Q";
	    };
    };

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
          pdf_reader = [
            { run = ''QT_QPA_PLATFORM=xcb sioyek --new-instance "$@"''; orphan = true; desc = "Sioyek"; }
          ];
          image_viewer = [
            { run = ''imv "$@"''; orphan = true; desc = "imv"; }
          ];
          video_player = [
            { run = ''mpv "$@"''; orphan = true; desc = "mpv"; }
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
