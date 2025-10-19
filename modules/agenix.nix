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
