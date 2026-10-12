{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.security;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.security = {
    enable = mkEnableOption "Enable gpg, password managers, etc.";

    gpg = {
      enable = mkEnableOption "Enable a custom GPG configuration" // {
        default = true;
      };

      sshKeys = mkOption {
        type = lib.types.listOf lib.types.str;
        description = "A list of SSH keys to be managed by GPG";
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      openssl
      tomb
      # for pass-otp
      zbar
    ];

    # Setup a Password Manager
    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [
        exts.pass-tomb
        exts.pass-otp
      ]);
      settings = {
        PASSWORD_STORE_DIR = "\$HOME/.password-store";
        PASSWORD_STORE_CLIP_TIME = "60";
      };
    };

    # GPG Settings
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
      sshKeys = cfg.gpg.sshKeys;
    };

    # Work around a systemd ordering cycle introduced by home-manager's
    # misc/ssh-auth-sock.nix module. It defines set-SSH_AUTH_SOCK.service with
    # `Before = gpg-agent-ssh.socket`; as an ordinary service it also gets an
    # implicit `After = basic.target`, and basic.target -> sockets.target ->
    # gpg-agent-ssh.socket (the socket is WantedBy sockets.target). systemd
    # breaks the resulting loop by dropping a random job in it, which on some
    # boots is the ssh socket itself, leaving S.gpg-agent.ssh unserved and
    # `ssh-add` unable to connect. Dropping the default deps from this oneshot
    # removes the basic.target ordering and breaks the cycle.
    systemd.user.services.set-SSH_AUTH_SOCK.Unit.DefaultDependencies = false;
  };
}
