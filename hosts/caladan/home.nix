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
    ../../home/development
    ../../home/neovim
    ../../home/rice
    ../../home
  ];

  home = {
    username = "schonfinkel";
    homeDirectory = "/home/schonfinkel";
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
  };

  homeModules.media = {
    enable = true;
  };

  homeModules.security = {
    enable = true;
  };

  homeModules.themes = {
    enable = true;
  };

  homeModules.zshell = {
    enable = true;
  };
}
