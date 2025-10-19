{
  modulesPath,
  lib,
  pkgs,
  options,
  ...
}:

{
  virtualisation.lxc = {
    enable = true;
    lxcfs.enable = true;
  };

  virtualisation.lxd.enable = true;
}
