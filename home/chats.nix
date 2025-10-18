{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.chats;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.homeModules.chats = {
    enable = mkEnableOption "Enable some 'Chat' applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      discord
      signal-desktop
      slack
    ];
  };
}
