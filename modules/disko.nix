{
  lib,
  config,
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
    mkForce
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.disko = {
    enable = mkEnableOption "Disko module";

    profile = mkOption {
      type = lib.types.str;
      description = "The disko layout profile to use. Only 'ext4' is supported right now.";
    };

    target = mkOption {
      type = lib.types.str;
      description = "The host target name (e.g. 'peano', 'euclid', 'tarski').";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      disko.devices = disko_settings.devices;
    }

    (mkIf (cfg.target == "aws") {
      boot.loader.grub = {
        enable = true;
        devices = mkForce [ "/dev/${target.device}" ];
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

      boot.loader.grub.devices = mkForce [ "/dev/vda" ];
    })

    (mkIf (target.hostname == "peano") {
      boot.loader.grub.devices = mkForce [ "/dev/vda" ];
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
      };
    })
  ]);
}
