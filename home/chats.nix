{
  config,
  lib,
  pkgs,
  ...
}:

let
  module_name = "homeModules.chats";
  cfg = config."${module_name}";
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options = {
    "${module_name}" = {
      enable = mkEnableOption "Enable some 'Chat' applications";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      discord
      signal-desktop
      slack
    ];
  };
}
