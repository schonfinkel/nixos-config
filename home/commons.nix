{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.commons;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.homeModules.commons = {
    enable = mkEnableOption "Enable the 'Commons' module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      brave
      curl
      croc
      dig
      exiftool
      fastfetch
      fd
      file
      ffmpeg
      flameshot
      graphviz
      htop
      # whois, ping, ping6, etc
      inetutils
      jq
      lsof
      nix-prefetch-git
      parallel
      pavucontrol
      pinentry-curses
      # lspci, ...
      pciutils
      # pkill, killall, pstree, fuser, ...
      psmisc
      rdap
      ripgrep
      sshfs
      smartmontools
      transmission_4-qt
      tree
      tree-sitter
      unar
      unzip
      # lsusb, etc
      usbutils
      wget
      zip
    ];

    services.udiskie = {
      enable = true;
      notify = true;
      automount = true;
      tray = "auto";
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "23.05";
  };
}
