{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.hyprland;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.hyprland = {
    enable = mkEnableOption "Enable/Disable common services and packages";
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

      # programs.uwsm = {
      #   enable = true;
      #   waylandCompositors = {
      #     hyprland = {
      #       prettyName = "Hyprland";
      #       comment = "Hyprland compositor managed by UWSM";
      #       binPath = "/run/current-system/sw/bin/start-hyprland";
      #       extraUWSMArgs = [
      #         "-e"
      #         "-D"
      #         "Hyprland"
      #       ];
      #     };
      #   };
      # };

      # programs.hyprlock = {
      #   enable = true;
      # };

      programs.xwayland.enable = true;
    })
  ]);
}
