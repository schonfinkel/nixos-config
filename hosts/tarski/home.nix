# Minimal home for the quick-install host. Only what is needed to be productive
# on a freshly imaged machine: a WM, an editor, a shell, and gpg/ssh.
#
# Notably NOT enabled (all available in ../../home if you want them): chats,
# emacs, media, programming, vscode, themes. Adding themes here pulls in stylix,
# which is what hosts/tarski/configuration.nix deliberately avoids.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Directories
    ../../home
  ];

  home = {
    username = "mbenevides";
    homeDirectory = "/home/mbenevides";
  };

  programs = {
    home-manager.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  homeModules.themes = {
    enable = true;
  };

  homeModules.commons = {
    enable = true;
  };

  homeModules.ghostty = {
    enable = true;
  };

  homeModules.hyprland = {
    enable = true;
    # Left at the module default; run `hyprctl monitors` on the real machine and
    # override here if the output name differs.
  };

  homeModules.neovim = {
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

  homeModules.zshell = {
    enable = true;
  };
}
