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
    allowUsers = [ "mbenevides" ];
  };

  image.modules.qemu-repart =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [ (modulesPath + "/image/repart.nix") ];

      # The image builder supplies its own single-disk layout and boot files.
      hostModules.disko.enable = lib.mkForce false;
      hostModules.impermanence.enable = lib.mkForce false;
      boot.loader.grub.enable = lib.mkForce false;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-partlabel/root";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-partlabel/boot";
          fsType = "vfat";
        };
      };

      image.repart = {
        name = "peano";
        partitions = {
          esp = {
            contents = {
              "/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI".source =
                "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";
              "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
                "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
            };
            repartConfig = {
              Type = "esp";
              Format = "vfat";
              Label = "boot";
              SizeMinBytes = "128M";
            };
          };
          root = {
            storePaths = [ config.system.build.toplevel ];
            repartConfig = {
              Type = "root";
              Format = "ext4";
              Label = "root";
              Minimize = "guess";
            };
          };
        };
      };
    };

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = hostId;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  users.mutableUsers = false;
  users.users.root.initialPassword = "nixos";
  users.users.mbenevides = {
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
