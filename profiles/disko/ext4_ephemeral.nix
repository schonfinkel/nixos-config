# Single-disk, unencrypted layout with an ephemeral (tmpfs) root.
#
#   ${target.device}  ESP (/boot) + BIOS boot + LVM "root_vg" -> swap, /nix, /persist
#
# This is profiles/disko/luks.nix without the LUKS container: same tmpfs root
# and same LVM layout, but no passphrase prompt at boot. Used by the
# quick-install "tarski" host and by "schonfinkel" -- use luks.nix instead if a
# machine needs its data protected at rest.
#
# The tmpfs root is what makes hostModules.impermanence meaningful: anything not
# declared there is genuinely gone on reboot. /persist must therefore be
# neededForBoot, since impermanence builds its bind mounts in stage 1.
{ target }:
let
  # Hardening options and the reasoning behind them, including why `noexec` is
  # absent, live in ./mount-options.nix.
  mountOpts = import ./mount-options.nix;

  # Size of the tmpfs root. Everything not persisted lives here -- /tmp, and the
  # parts of $HOME impermanence does not bind-mount -- so it has to be big
  # enough for a Nix build's scratch space. Override per host with `rootSize` in
  # profiles/settings.nix.
  rootSize = target.rootSize or "8G";
in
{
  devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = mountOpts.tmpfsRoot ++ [
        "size=${rootSize}"
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
            # Keeps a legacy/BIOS boot path available on older machines.
            boot = {
              size = "1M";
              type = "EF02";
            };
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
