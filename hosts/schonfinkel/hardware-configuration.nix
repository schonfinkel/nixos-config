# Hardware scan results for "schonfinkel".
#
# NOTE: unlike caladan/euclid this file deliberately declares NO `fileSystems`
# or `swapDevices` entries -- the whole layout comes from disko (see
# profiles/disko/ext4_ephemeral.nix). When regenerating it on the real machine
# use:
#
#   nixos-generate-config --no-filesystems --show-hardware-config
#
# and keep only the module/microcode/DHCP bits below.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [
    # Needed in stage 1 to activate root_vg.
    "dm-snapshot"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
