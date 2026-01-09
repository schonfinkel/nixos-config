{
  config,
  lib,
  modulesPath,
  pkgs,
  options,
  specialArgs,
  ...
}:

{
  # https://wiki.nixos.org/wiki/Waydroid
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
}
