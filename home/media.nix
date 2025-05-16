{pkgs, ...}:

{
  home.packages = with pkgs; [
    mpv
    ncmpcpp
    graphviz
  ];

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
}
