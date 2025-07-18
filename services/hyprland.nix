{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl

    # Screenshot functionality
    hyprshot

    networkmanagerapplet

    # Notification daemon
    mako

    pyprland
    hyprpicker
    hyprcursor
    hyprlock
    hypridle
    hyprpaper

    waybar
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
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  programs.hyprlock = {
    enable = true;
  };

  programs.xwayland.enable = true;
}
