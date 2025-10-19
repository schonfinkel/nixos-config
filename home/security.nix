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
  };
}
