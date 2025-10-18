{
  config,
  lib,
  pkgs,
  ...
}:

let
  module_name = "homeModules.themes";
  cfg = config."${module_name}";
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options = {
    "${module_name}" = {
      enable = mkEnableOption "Enable custom themes with Stylix";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    ];

    stylix.targets = {
      waybar.enable = true;
      wofi.enable = true;
      neovim.enable = true;
      hyprland.enable = true;
      kitty.enable = true;
    };
  };
}
