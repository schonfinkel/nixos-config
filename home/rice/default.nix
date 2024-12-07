{ pkgs, config, inputs, system, ... }:

{
  imports =
    [
      (import ./kitty.nix { inherit pkgs config; })
      #(import ./alacritty.nix { inherit pkgs config; })
    ];

  stylix.targets.waybar.enable = true;
  stylix.targets.wofi.enable = true;
  stylix.targets.hyprland.enable = false;

  home.packages = with pkgs; [
  ];
}
