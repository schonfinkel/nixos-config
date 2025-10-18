{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.agenix;
  impermanence_module = config.hostModules.impermanence;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.agenix = {
    enable = mkEnableOption "Enable/Disable Agenix Secrets";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      # Agenix setup
      age = {
        secrets = {
          user_password = {
            file = ../secrets/user_password.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "0440";
          };

          user_ssh_key = {
            file = ../secrets/user_ssh_key.age;
            mode = "0440";
          };
        };
      };
    })

    # Impermance-based configs
    # https://discourse.nixos.org/t/how-to-define-actual-ssh-host-keys-not-generate-new/31775/8
    # If persistence is enabled
    (mkIf (impermanence_module.enable) {
      # Age
      age = {
        identityPaths = [
          "${impermanence_module.persistDirectory}/etc/agenix/server_key"
        ];
      };

      # Agenix Keys
      environment.persistence."${impermanence_module.persistDirectory}" = {
        directories = [
          "/etc/agenix"
        ];
      };
    })

    # Otherwise
    (mkIf (!impermanence_module.enable) {
      # Age
      age = {
        identityPaths = [
          "/etc/agenix/server_ssh"
        ];
      };
    })
  ]);
}
