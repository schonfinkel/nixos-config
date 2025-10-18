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
          hashed_password = {
            file = ../secrets/hashed_password.age;
            mode = "0440";
          };
        };
      };
    })
  ]);
}
