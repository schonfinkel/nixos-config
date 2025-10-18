{
  config,
  lib,
  pkgs,
  ...
}:

let
  module_name = "homeModules.security";
  cfg = config."${module_name}";
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options = {
    "${module_name}" = {
      enable = mkEnableOption "Enable security apps, password managers, etc.";
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
  };
}
