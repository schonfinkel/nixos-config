{pkgs, ...}:

{
  home.packages = with pkgs; [
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
    gnumake
    htop
    jq
    kooha
    lsof
    nix-prefetch-git
    parallel
    pavucontrol
    #pinentry
    pinentry-curses
    pciutils    # lspci
    psmisc      # pkill, killall, pstree, fuser
    ripgrep
    sshfs
    smartmontools
    transmission_4-qt
    tree
    tree-sitter
    unar
    unzip
    usbutils    # lsusb
    wget
    zip
  ];
}
