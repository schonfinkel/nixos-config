{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.themes;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.themes = {
    enable = mkEnableOption "Enable custom themes with Stylix";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    ];

    stylix.targets = {
      hyprland.enable = true;
      kitty.enable = true;
      neovim.enable = true;
      mako.enable = true;
      waybar.enable = true;
      wofi.enable = true;
    };
  };
}
