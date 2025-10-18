{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  module_name = "modules.hostModules.ssh";
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
      enable = mkEnableOption "Enable/Disable Agenix Secrets";

      allowUsers = mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };

      port = mkOption {
        type = lib.types.int;
        default = 22;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      services.openssh = {
        enable = true;
        ports = [ cfg.port ];
        settings = {
          PasswordAuthentication = false;
          AllowUsers = cfg.allowUsers;
          X11Forwarding = false;
          # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
          PermitRootLogin = "prohibit-password";
        };
      };

      services.fail2ban = {
        enable = true;
        jails.DEFAULT = ''
          bantime = 3600
        '';
        jails.ssh = ''
          filter = sshd
          maxretry = 4
          action = iptables[name=ssh, port=ssh, protocol=tcp]
          enabled = true
        '';
      };
    })
  ]);
}
