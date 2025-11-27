{
  lib,
  config,
  modulesPath,
  hostId,
  pkgs,
  profile,
  target,
  specialArgs,
  ...
}:
let
  extraPaths =
    if target.hostname == "peano" then
      [
        "${modulesPath}/profiles/qemu-guest.nix"
      ]
    else
      [ ];
in
{
  imports = [
    ../../modules
    ../../profiles/users.nix
  ]
  ++ extraPaths;

  modules.common = {
    enable = true;
  };

  modules.disko = {
    enable = true;
    profile = profile;
    target = target;
  };

  modules.impermanence = {
    enable = true;
  };

  modules.ssh = {
    enable = true;
  };

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
