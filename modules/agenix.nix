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
      type = lib.types.listOf lib.types.path;
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

        # Private key of the SSH key pair. This is the other pair of what was supplied
        # in `secrets.nix`.
        #
        # This tells `agenix` where to look for the private key.
        identityPaths = paths;
      };
    })
  ]);
}
