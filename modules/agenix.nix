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

    paths = mkOption {
      type = lib.types.listOf lib.types.str;
    };

    luksKeyFile = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Absolute path at which the decrypted `luks_data.age` key is
        materialised, for hosts that enroll an agenix-managed key as an extra
        LUKS slot on a secondary disk. Null (the default) declares nothing.

        This is a recovery/automation credential, not the boot path: the initrd
        opens those volumes from the passphrase. The key is written as a real
        file rather than a symlink into /run/agenix so it stays put across
        reboots, which means it belongs on a persisted filesystem -- in practice
        `''${persistDirectory}/luks/...`.
      '';
      example = "/persist/luks/data.key";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      # Agenix setup
      age = {
        secrets = {
          hashed_password = {
            file = ../secrets/hashed_password.age;
            mode = "0440";
          };
        };
      };
    })

    # Key file for a LUKS volume that is opened outside the initrd.
    (mkIf (cfg.luksKeyFile != null) {
      age.secrets.luks_data = {
        file = ../secrets/luks_data.age;
        path = cfg.luksKeyFile;
        # Decrypt straight to `path` instead of symlinking into /run/agenix.
        symlink = false;
        mode = "0400";
        owner = "root";
      };
    })

    # Impermance-based configs
    # https://discourse.nixos.org/t/how-to-define-actual-ssh-host-keys-not-generate-new/31775/8
    # If persistence is enabled
    (mkIf (impermanence_module.enable) {
      # Age
      age = {
        # Private key of the SSH key pair. This is the other pair of what was supplied
        # in `secrets.nix`.
        #
        # This tells `agenix` where to look for the private key.
        identityPaths = [
          "${impermanence_module.persistDirectory}/etc/ssh/ssh_host_ed25519_key"
          "${impermanence_module.persistDirectory}/etc/ssh/ssh_host_rsa_key"
        ]
        ++ (map (x: "${impermanence_module.persistDirectory}${x}") cfg.paths);
      };
    })
    # Otherwise
    (mkIf (!impermanence_module.enable) {
      # Age
      age = {
        identityPaths = [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_rsa_key"
        ]
        ++ cfg.paths;
      };
    })
  ]);
}
