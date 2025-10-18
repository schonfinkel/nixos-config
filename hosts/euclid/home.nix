{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    username = "mbenevides";
    homeDirectory = "/home/mbenevides";
  };

  imports = [
    # Directories
    ../../home/development
    ../../home/neovim
    ../../home/rice
    ../../home
  ];

  programs = {
    home-manager.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home modules
  modules.home = {
    common = {
      enable = true;
    };

    chats = {
      enable = true;
    };

    emacs = {
      enable = true;
    };

    hyprland = {
      enable = true;
    };

    media = {
      enable = true;
    };

    security = {
      enable = true;
    };

    themes = {
      enable = true;
    };

    zshell = {
      enable = true;
    };
  };
}
