{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.ssh;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.ssh = {
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

      programs.ssh.agentTimeout = "1h";
      programs.ssh.startAgent = true;

      services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime-increment = {
          # Enable increment of bantime after each violation
          enable = true;
          multipliers = "1 2 4 8 16 32 64";
          # Do not ban for more than 1 week
          maxtime = "168h";
          # Calculate the bantime based on all the violations
          overalljails = true;
        };
        jails = {
          sshd = {
            settings = {
              enabled = true;
              port = "ssh";
              filter = "sshd";
              logpath = "/var/log/auth.log";
              maxretry = 5;
              bantime = 600;
            };
          };
        };
      };
    })
  ]);
}
