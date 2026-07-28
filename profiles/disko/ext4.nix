{ target }:
let
  # Only the VM needs an image size
  extraAttrs = if target.hostname == "peano" then { imageSize = "40G"; } else { };

  # Hardening options and the reasoning behind them, including why `noexec` is
  # absent, live in ./mount-options.nix.
  mountOpts = import ./mount-options.nix;
in
{
  devices = {
    disk.main = extraAttrs // {
      device = "/dev/${target.device}";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
          };
          esp = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = mountOpts.esp;
            };
          };
          swap = {
            name = "swap";
            size = target.swap.size;
            content.type = "swap";
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "root_vg";
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
            size = "10%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = mountOpts.default;
            };
          };

          nix = {
            size = "45%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = mountOpts.default;
            };
          };

          persist = {
            size = "45%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
              mountOptions = mountOpts.default;
            };
          };
        };
      };
    };
  };
}
