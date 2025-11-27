{
  lib,
  config,
  modulesPath,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.disko;
  settings = import ../profiles/settings.nix;
  disko_profile_path = ../profiles/disko/. + "/${cfg.profile}.nix";
  target = settings."${cfg.target}";
  disko_settings = import disko_profile_path { target = target; };
  inherit (lib)
    mkEnableOption
    mkIf
    mkForce
    mkMerge
    mkOption
    ;
in
{
  options.modules.disko = {
    enable = mkEnableOption "Disko module";

    profile = mkOption {
      type = lib.types.str;
      description = "The target to use for the disko module. Only 'ext4' is supported right now.";
    };

    target = mkOption {
      type = lib.types.str;
      description = "The profile to use for the disko module. Can be either 'aws', 'mgc' or 'vm'.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      disko.devices = disko_settings.devices;
    })

    (mkIf (cfg.target == "aws") {
      boot.loader.grub = {
        enable = true;
        devices = lib.mkForce [ "/dev/${target.device}" ];
      };
    })

    (mkIf (cfg.target == "mgc") {
      boot = {
        initrd.availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
        ];
        kernelModules = [ "kvm-intel" ];
      };

      boot.loader.grub.devices = lib.mkForce [ "/dev/vda" ];
    })

    (mkIf (cfg.target == "vm") {
      boot.loader.grub.devices = lib.mkForce [ "/dev/vda" ];
      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];
      boot.kernelModules = [ ];

      virtualisation.vmVariantWithDisko = {
        # 40GB in Mb
        virtualisation.diskSize = 40960;
        # 4GB in Mb
        virtualisation.memorySize = 4096;
        # TODO: Check it layer how we can make this usable on MacOS
        # For running VM on macos: https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/
        # virtualisation.host.pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
      };
    })
  ]);
}
