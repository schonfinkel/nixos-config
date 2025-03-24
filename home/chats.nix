{pkgs, ...}:

{
  home.packages = with pkgs; [
    discord
    signal-desktop
    slack
  ];
}
