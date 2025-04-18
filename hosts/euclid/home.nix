{ pkgs, ... }: {
  home = {
    username = "mbenevides";
    homeDirectory = "/home/mbenevides";
  };

  imports =
    [
      # Directories
      ../../home/browsers.nix
      ../../home/development
      ../../home/chats.nix
      ../../home/common.nix
      ../../home/editors.nix
      ../../home/emacs.nix
      ../../home/hyprland.nix
      ../../home/security.nix
      ../../home/ranger.nix
      ../../home/rice
      ../../home/zshell.nix
    ];

  programs = {
    home-manager.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}

