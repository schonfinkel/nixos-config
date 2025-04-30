{pkgs, ...}:

{
  imports =
    [
      ./cloud.nix
      ./git.nix
      ./kubernetes.nix
      ./programming.nix
    ];

  manual.manpages.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv = {
      enable = true;
    };
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 34560000;
    defaultCacheTtlSsh = 34560000;
    maxCacheTtl = 34560000;
    maxCacheTtlSsh = 34560000;
    pinentry = {
      package = pkgs.pinentry-curses;
    };
    sshKeys = [
      "23C94318A1D57DA26574677539EC504CB2A49981"
    ];
  };
}
