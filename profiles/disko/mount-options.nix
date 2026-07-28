# Shared mount options for the disko layouts in this directory.
#
# Rationale, following
# https://catinashell.de/posts/hardening-nixos-impermanence-setup-with-noexec/
#
# `nosuid` is safe on every filesystem these profiles declare: NixOS keeps all
# setuid binaries in /run/wrappers/bin, which is its own tmpfs mounted
# specifically so a nosuid root still works. Nothing legitimate depends on the
# bit being honoured on /, /nix or /persist. `nodev` likewise -- real device
# nodes live on devtmpfs.
#
# `noexec` is deliberately NOT in `default`, even on the ephemeral tmpfs root:
#
#   - /tmp is a plain directory on the root filesystem (hosts set
#     boot.tmp.cleanOnBoot, not boot.tmp.useTmpfs), and Nix builds execute
#     binaries from their build directory. noexec there breaks builds.
#   - modules/impermanence.nix persists *subdirectories* of $HOME, not the home
#     root, so ~/.cache and ~/.local/share sit on the root too. Plenty of
#     tooling execs out of those.
#   - it also protects less than it appears: impermanence's bind mounts take
#     their options from /persist, not from /, so noexec on / would never apply
#     to any persisted path.
#
# Revisit only after /tmp has its own exec-permitting mount.
{
  # /, /nix, /persist -- anything that has to run code or host a Nix store.
  default = [
    "defaults"
    "noatime"
    "nosuid"
    "nodev"
  ];

  # The ESP gets the full set. Nothing execs from it at runtime -- the firmware
  # reads it before the kernel has mounted anything -- and fmask=0177 clears the
  # exec bit that a bare umask=0077 leaves set on every file.
  esp = [
    "fmask=0177"
    "dmask=0077"
    "noexec"
    "nosuid"
    "nodev"
  ];

  # Ephemeral tmpfs root. Size and mode are per-profile, so they are appended by
  # the caller.
  tmpfsRoot = [
    "defaults"
    "nosuid"
    "nodev"
  ];
}
