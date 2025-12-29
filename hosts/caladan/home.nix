{
  pkgs,
  config,
  home,
  inputs,
  system,
  ...
}:

{
  imports = [
    # Directories
    ../../home
  ];

  home = {
    username = "leto";
    homeDirectory = "/home/leto";
  };

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
    monitors = [
      "HDMI-A-1,highres,0x0,2"
    ];
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
}
