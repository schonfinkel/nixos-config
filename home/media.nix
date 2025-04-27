{pkgs, user, ...}:

let
  dotfiles = ../dotfiles;
  # Convert a string to dotfiles path format
  dpath = p: builtins.toString "${dotfiles}/${p}";
in
{
  home.packages = with pkgs; [
    mpv
    ncmpcpp
    graphviz
    obs-studio
  ];

  programs.newsboat = {
    enable = true;
  };

  services.mpd = {
    enable = true;
    dataDir = builtins.toPath "/home/${user}/.mpd";
    musicDirectory = builtins.toPath "/home/${user}/Music";
    network = {
      listenAddress = "127.0.0.1";
      port = 6600;
    };
    extraConfig = ''
      audio_output {
        type      "pulse"
        name      "Local Music Player Daemon"
      }
      audio_output {
        type      "fifo"
        name      "my_fifo"
        path      "/tmp/mpd.fifo"
        format    "44100:16:2"
      }
    '';
  };

  home.file.".ncmpcpp/config".source = dpath "ncmpcpp/config";

  xdg.configFile = {
    "mpv" = {
      source = dpath "mpv";
      recursive = true;
    };
    "zathura/zathurarc".source = dpath "zathura/zathurarc";
  };
}
