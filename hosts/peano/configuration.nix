{
  lib,
  modulesPath,
  hostId,
  profile,
  target,
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
    ../../modules/agenix.nix
    ../../modules/commons.nix
    ../../modules/disko.nix
    ../../modules/impermanence.nix
    ../../modules/ssh.nix
  ]
  ++ extraPaths;

  hostModules.disko = {
    enable = true;
    profile = profile;
    target = "peano";
  };

  hostModules.commons = {
    enable = true;
    hostName = "peano";
  };

  hostModules.impermanence = {
    enable = true;
  };

  hostModules.ssh = {
    enable = true;
    allowUsers = [ "schonfinkel" ];
  };

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  users.mutableUsers = false;
  users.users.root.initialPassword = "nixos";
  users.users.schonfinkel = {
    uid = 1000;
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [
      "audio"
      "disk"
      "input"
      "networkmanager"
      "tty"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5HDsDVFBscGYZ7Tb0dkx9bUUxDnEIB3s+T4pbpvc3D default"
    ];
  };

  system.stateVersion = "24.11";
}
