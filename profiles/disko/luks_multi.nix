# Two-disk, LUKS-encrypted layout with an ephemeral (tmpfs) root.
#
#   ${target.device}      ESP (/boot) + LUKS -> LVM "main_vg" -> swap, /nix, /persist
#   ${target.dataDevice}  LUKS -> LVM "data_vg" -> /persist/data
#
# Both containers are unlocked in the initrd and are meant to carry the *same*
# passphrase: with systemd in stage 1 the password is cached in the kernel
# keyring and reused for the second volume, so it is typed once per boot. That
# matters because impermanence sets its bind mounts up in stage 1, which means
# every persistence root -- /persist and /persist/data alike -- has to be
# available before stage 2 starts.
#
# The data disk additionally gets the agenix-managed key from
# secrets/luks_data.age enrolled as a second key slot, so it can be reopened
# without the passphrase for recovery or unattended remounts.
{ target }:
let
  # Hardening options and the reasoning behind them, including why `noexec` is
  # absent, live in ./mount-options.nix.
  mountOpts = import ./mount-options.nix;

  # Where the extra key slot is read from *while disko formats the disks* (i.e.
  # from the installer). At runtime agenix materialises the same key at
  # /persist/luks/data.key -- see hostModules.agenix.luksKeyFile.
  installKeyFile = "/tmp/data.key";
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
      # System disk: boot, store, and persisted state.
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

      # Bulk data disk.
      data = {
        device = "/dev/${target.dataDevice}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptdata";
                settings.allowDiscards = true;
                # Slot 0 is the passphrase (prompted for at install time -- use
                # the same one as the system disk so stage 1 can reuse it from
                # the keyring). Slot 1 is the agenix key, added on top.
                additionalKeyFiles = [ installKeyFile ];
                content = {
                  type = "lvm_pv";
                  vg = "data_vg";
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

      data_vg = {
        type = "lvm_vg";
        lvs = {
          data = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist/data";
              mountOptions = mountOpts.default;
            };
          };
        };
      };
    };
  };
}
