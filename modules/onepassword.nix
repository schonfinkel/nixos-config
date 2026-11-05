{
  lib,
  config,
  ...
}:

let
  cfg = config.hostModules.onepassword;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    ;
in
{
  options.hostModules.onepassword = {
    enable = mkEnableOption "Enable/Disable the 1Password CLI and desktop app";

    polkitPolicyOwners = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users allowed to unlock 1Password through polkit (system authentication),
        which the CLI and browser integrations rely on.
      '';
    };
  };

  config = mkIf cfg.enable {
    # The setgid (onepassword-cli) wrapper the desktop app talks to.
    programs._1password.enable = true;

    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = cfg.polkitPolicyOwners;
    };
  };
}
