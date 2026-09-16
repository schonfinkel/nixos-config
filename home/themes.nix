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
      # Emacs is themed by Noctalia instead (see home/noctalia.nix and
      # dotfiles/emacs.d/ui.el), so stylix no longer targets it.
      # Hyprland is configured via hyprland.lua (the HM module is disabled), so
      # the stylix writer has nothing to target; border colors are injected into
      # the Lua directly instead. See home/hyprland.nix.
      hyprland.enable = false;
      ghostty.enable = true;
      neovim.enable = true;
      noctalia.enable = true;
    };
  };
}
