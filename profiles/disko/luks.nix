# Single-disk, LUKS-encrypted layout with an ephemeral (tmpfs) root.
#
#   ${target.device}  ESP (/boot) + LUKS -> LVM "main_vg" -> swap, /nix, /persist
#
# This is profiles/disko/luks_multi.nix with the bulk data disk removed, for
# machines that only have one drive (or whose second drive has died). The
# system-disk half is deliberately identical, so moving between the two
# profiles does not reshape anything that is already installed.
#
# To go back to two disks once a replacement is fitted, in the host config:
#   - hostModules.disko.profile      = "luks_multi";
#   - re-add fileSystems."/persist/data".neededForBoot = true;
#   - re-add hostModules.impermanence.dataDirectory / dataUserDirectories
#   - set the new drive's name in profiles/settings.nix (dataDevice)
# then run `disko --mode disko` again -- it will reformat *both* disks, so back
# /persist up first.
{ target }:
let
  # Hardening options and the reasoning behind them, including why `noexec` is
  # absent, live in ./mount-options.nix.
  mountOpts = import ./mount-options.nix;
in
{
  devices = {
    # Ephemeral root. Anything not declared in modules/impermanence.nix is gone
    # on the next boot.
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = mountOpts.tmpfsRoot ++ [
        "size=8G"
        "mode=755"
      ];
    };

    disk = {
      main = {
        device = "/dev/${target.device}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = mountOpts.esp;
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptmain";
                settings.allowDiscards = true;
                content = {
                  type = "lvm_pv";
                  vg = "main_vg";
                };
              };
            };
          };
        };
      };
    };

    lvm_vg = {
      main_vg = {
        type = "lvm_vg";
        lvs = {
          # Swap sits inside the LUKS container, so hibernation works without a
          # second passphrase and without random encryption.
          swap = {
            size = target.swap.size;
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };

          nix = {
            size = "50%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = mountOpts.default;
            };
          };

          persist = {
            size = "100%FREE";
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
