{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    username = "schonfinkel";
    homeDirectory = "/home/schonfinkel";
  };

  imports = [
    # Directories
    ../../home
  ];

  programs = {
    home-manager.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Custom Home modules
  homeModules.commons = {
    enable = true;
  };

  homeModules.chats = {
    enable = true;
  };

  homeModules.emacs = {
    enable = true;
  };

  homeModules.hyprland = {
    enable = true;
  };

  homeModules.kitty = {
    enable = true;
  };

  homeModules.media = {
    enable = true;
  };

  homeModules.neovim = {
    enable = true;
  };

  homeModules.programming = {
    enable = true;
  };

  homeModules.security = {
    enable = true;
    gpg = {
      enable = true;
      sshKeys = [
        "23C94318A1D57DA26574677539EC504CB2A49981"
      ];
    };
  };

  homeModules.themes = {
    enable = true;
  };

  homeModules.zshell = {
    enable = true;
  };

  homeModules.vscode = {
    enable = true;
  };
}
