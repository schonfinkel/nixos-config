{
  pkgs,
  lib,
  config,
  options,
  modulesPath,
  ...
}:

{
  virtualisation.libvirtd.enable = true;
}
