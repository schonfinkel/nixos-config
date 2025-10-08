{
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.agenix;
in
{
  options.modules.agenix = {
    enable = mkEnableOption "Enable/Disable Agenix Secrets";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Agenix setup
      age = {
        secrets = {
          pg_user_lyceum = {
            file = ../secrets/pg_user_lyceum.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "0440";
            path = "/etc/agenix/pg_user_lyceum";
          };

          pg_user_migrations = {
            file = ../secrets/pg_user_migrations.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "0440";
            path = "/etc/agenix/pg_user_migrations";
          };

          server_ssh = {
            file = ../secrets/server_ssh.age;
            path = "/etc/agenix/server_ssh";
          };
        };
      };

      # SSH
      services.openssh = {
        hostKeys = [
          {
            type = "ed25519";
            path = config.age.secrets.server_ssh.path;
          }
        ];
        extraConfig = "HostKey /run/agenix/server_ssh";
      };
    })

    # Impermance-based configs
    # https://discourse.nixos.org/t/how-to-define-actual-ssh-host-keys-not-generate-new/31775/8
    # If persistence is enabled
    (mkIf (impermanence_module.enable) {
      # Age
      age = {
        identityPaths = [
          "${impermanence_module.directory}/etc/agenix/server_key"
        ];
      };
      virtualisation.vmVariantWithDisko.agenix.age.sshKeyPaths = [
        "${impermanence_module.directory}/etc/agenix/server_key"
      ];

      # Agenix Keys
      environment.persistence."${impermanence_module.directory}" = {
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
      virtualisation.vmVariantWithDisko.agenix.age.sshKeyPaths = [
        "/etc/agenix/server_ssh"
      ];
    })

    # Only run this for local VM builds
    (mkIf (disko_module.profile == "vm") {
      # SSH
      services.openssh = {
        hostKeys = [
          {
            type = "ed25519";
            path = config.age.secrets.server_ssh.path;
          }
        ];
      };
    })
  ];
}
