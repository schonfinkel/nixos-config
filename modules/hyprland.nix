{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  module_name = "modules.hostModules.hyprland";
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
      enable = mkEnableOption "Enable/Disable common services and packages";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = with pkgs; [
        # Screenshot functionality
        hyprshot

        # Notification daemon
        mako

        pyprland
        hyprpicker
        hyprcursor
        hyprlock
        hypridle
        hyprpaper

        xwayland
        waybar
        wayland
        wofi

        # wl-copy and wl-paste for copy/paste
        # from stdin / stdout
        wl-clipboard

        # Screensharing
        wireplumber
        xdg-desktop-portal-hyprland

        # Logout
        wlogout
      ];

      services.displayManager = {
        sessionPackages = [ pkgs.hyprland ];
      };

      # hyprland setup
      programs.hyprland = {
        enable = true;
        # Whether to enable XWayland
        xwayland.enable = true;
        # Recommended for most users
        withUWSM = true;
        # set the flake package
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        # make sure to also set the portal package, so that they are in sync
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

      programs.hyprlock = {
        enable = true;
      };

      programs.xwayland.enable = true;
    })
  ]);
}
