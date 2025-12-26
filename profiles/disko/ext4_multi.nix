{ target }:
let
  # Apply imageSize only if target is the VM
  extraAttrs = if target.hostname == "peano" then { imageSize = "40G"; } else { };

  defaultMountOptions = [
    "defaults"
    "noatime"
  ];
in
{
  disko.devices = {
    disk = {
      # FAST NVME DRIVE: Boot and Home
      nvme = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            home = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/home";
              };
            };
          };
        };
      };

      # SYSTEM SATA DRIVE: Root, Nix, and Persist via LVM
      main = extraAttrs // {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # Bios boot partition (if needed for GRUB/Legacy)
            boot = {
              size = "1M";
              type = "EF02";
            };
            # The rest of the SATA disk goes to LVM
            root = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "root_vg";
              };
            };
          };
        };
      };
    };

    lvm_vg = {
      root_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "10%FREE"; # Small root, using the rest for Nix/Persist
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = defaultMountOptions;
            };
          };
          nix = {
            size = "45%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = defaultMountOptions;
            };
          };
          persist = {
            size = "45%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
              mountOptions = defaultMountOptions;
            };
          };
        };
      };
    };
  };
}