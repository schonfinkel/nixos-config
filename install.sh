#!/usr/bin/env bash
#
# install.sh -- install a host from this flake onto a fresh machine.
#
# Defaults to "tarski", the quick-install target: disko + impermanence,
# Hyprland, and the mbenevides user. See hosts/tarski/configuration.nix for what
# it deliberately leaves out. --host installs any other host in the flake.
#
# Three modes. The first two prepare things and exit without touching a disk;
# only the third installs:
#
#   sudo ./install.sh --setup
#       Make the machine running this script able to drive the flake: add
#       nix.settings.experimental-features and programs.git.lfs.enable to
#       /etc/nixos/configuration.nix and nixos-rebuild switch. Run once, first.
#
#   ./install.sh --gen-keys --host schonfinkel [--host-keys DIR]
#       Generate the SSH host keys a host needs when its credentials come from
#       agenix. Writes to DIR (default /tmp/<host>-keys) and prints the public
#       halves to paste into secrets/secrets.nix. No root required.
#
#   sudo ./install.sh                      # pick the disk interactively
#   sudo ./install.sh --disk /dev/nvme0n1  # non-interactive target
#   sudo ./install.sh --disk /dev/sda --host tarski --flake .
#   sudo ./install.sh --host schonfinkel --host-keys /tmp/schonfinkel-keys
#
# --host-keys DIR holds the private identities agenix decrypts with, named by
# the basename the target expects (ssh_host_ed25519_key, ssh_host_rsa_key,
# default_ed25519). They are planted on the persisted volume between disko and
# nixos-install, which is what keeps a `users.mutableUsers = false` host from
# booting with every account locked. The script works out whether the chosen
# host needs them and refuses to start if they are missing.
#
# THIS ERASES THE TARGET DISK COMPLETELY.

set -euo pipefail

HOST="tarski"
FLAKE="."
DISK=""
HOST_KEYS=""
ASSUME_YES=0
MODE_SETUP=0
MODE_GEN_KEYS=0

die() {
  printf '\nerror: %s\n' "$*" >&2
  exit 1
}
info() { printf '\n==> %s\n' "$*"; }

usage() {
  sed -n '3,/^# THIS ERASES/p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --disk)  DISK="${2:-}"; shift 2 ;;
    --host)  HOST="${2:-}"; shift 2 ;;
    --flake) FLAKE="${2:-}"; shift 2 ;;
    --host-keys) HOST_KEYS="${2:-}"; shift 2 ;;
    --setup) MODE_SETUP=1; shift ;;
    --gen-keys) MODE_GEN_KEYS=1; shift ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    -h|--help) usage 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
done

# Where key material lives when nobody says otherwise. --gen-keys writes here
# and an install reads it back, so the common path is two commands with no paths
# typed at all. Per-host, so several targets can be prepared side by side.
#
# Note this is only the *source*: the destinations always come from the flake
# (config.age.identityPaths), never from this directory's name.
HOST_KEYS_DEFAULT="/tmp/${HOST}-keys"

# ---------------------------------------------------------------------------
# Preflight
#
# --setup and --gen-keys are preparation steps, so they are held to less than a
# real install: --gen-keys writes nothing outside its output directory and does
# not need root at all.
# ---------------------------------------------------------------------------

MODE_INSTALL=1
if [ "$MODE_SETUP" -eq 1 ] || [ "$MODE_GEN_KEYS" -eq 1 ]; then
  MODE_INSTALL=0
fi

if [ "$MODE_INSTALL" -eq 1 ] || [ "$MODE_SETUP" -eq 1 ]; then
  [ "$(id -u)" -eq 0 ] || die "must run as root (use sudo)"
fi

command -v nix >/dev/null 2>&1 || die "missing required command: nix"

if [ "$MODE_INSTALL" -eq 1 ]; then
  for cmd in lsblk sgdisk wipefs blkid; do
    command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
  done

  [ -d /sys/firmware/efi ] ||
    die "not booted in UEFI mode. $HOST uses systemd-boot; reboot the installer
       in UEFI mode (disable CSM/Legacy in the firmware) and try again."
fi

if [ "$MODE_GEN_KEYS" -eq 1 ]; then
  command -v ssh-keygen >/dev/null 2>&1 || die "missing required command: ssh-keygen"
fi

# --setup only touches the machine it runs on, so it does not need the flake.
if [ "$MODE_SETUP" -eq 0 ]; then
  if [ ! -e "$FLAKE/flake.nix" ] && [ "${FLAKE#*:}" = "$FLAKE" ]; then
    die "no flake.nix at '$FLAKE' -- run this from the repo root or pass --flake"
  fi
fi

# Flakes only see git-tracked files. A freshly cloned repo is fine; a dirty one
# with untracked additions silently installs the committed version instead.
if [ -d "$FLAKE/.git" ] && command -v git >/dev/null 2>&1; then
  if [ -n "$(git -C "$FLAKE" status --porcelain --untracked-files=normal 2>/dev/null | grep '^??' || true)" ]; then
    printf '\nwarning: untracked files present; nix will ignore them.\n'
    git -C "$FLAKE" status --short --untracked-files=normal | grep '^??' || true
  fi
fi

# ---------------------------------------------------------------------------
# Prepare the machine running the installer -- only under --setup, so an
# install never reconfigures the machine it is launched from as a side effect.
#
# Two things it needs before it can drive this flake:
#
#   - flakes. Everything below uses --flake, and nixos-install spawns its own
#     nix processes that do not inherit this script's
#     --extra-experimental-features. NIX_CONFIG covers those for this run;
#     editing /etc/nixos/configuration.nix makes it stick, so a re-run -- or any
#     nix command you type afterwards -- does not need the flags again.
#   - git-lfs, so cloning this repo (or anything else) checks out real file
#     contents rather than LFS pointer stubs.
#
# Both go into /etc/nixos/configuration.nix and are applied with a single
# `nixos-rebuild switch`. Each line is added only if it is not already there,
# so re-running the script is a no-op.
# ---------------------------------------------------------------------------

if ! printf '%s' "${NIX_CONFIG:-}" | grep -q 'experimental-features'; then
  export NIX_CONFIG="experimental-features = nix-command flakes"
fi

FLAKES_LINE='  nix.settings.experimental-features = [ "nix-command" "flakes" ];'
LFS_LINE='  programs.git.lfs.enable = true;'

prepare_installer_system() {
  cfg="/etc/nixos/configuration.nix"
  wanted=()

  if nix --extra-experimental-features nix-command config show experimental-features 2>/dev/null |
    grep -qw flakes; then
    info "Flakes already enabled system-wide"
  else
    wanted+=("$FLAKES_LINE")
  fi

  # git-lfs rides along with the same rebuild rather than getting its own
  # question: if we are editing configuration.nix at all, declare it. A git-lfs
  # binary already on PATH is not the same thing -- it can come from a
  # nix-shell that disappears with this session.
  wanted+=("$LFS_LINE")

  # The installation media has no /etc/nixos, and its /etc/nix/nix.conf is a
  # read-only symlink into the store. NIX_CONFIG above covers flakes there; for
  # git-lfs use `nix-shell -p git-lfs` or add it to the ISO.
  if [ ! -f "$cfg" ]; then
    info "No $cfg (live installer?) -- flakes come from NIX_CONFIG for this run"
    return 0
  fi

  if ! command -v nixos-rebuild >/dev/null 2>&1; then
    info "nixos-rebuild not available -- flakes come from NIX_CONFIG for this run"
    return 0
  fi

  # Already declared but not yet active (someone edited and did not switch):
  # drop it from the list rather than adding a duplicate attribute, which is an
  # eval error in Nix.
  pending=()
  for line in "${wanted[@]}"; do
    case "$line" in
      *experimental-features*) key='experimental-features' ;;
      *) key='git.lfs.enable' ;;
    esac
    if grep -q "$key" "$cfg"; then
      info "$cfg already sets $key -- leaving it alone"
    else
      pending+=("$line")
    fi
  done

  [ "${#pending[@]}" -gt 0 ] || return 0

  printf '\n'
  printf 'The machine running this script needs changes to %s:\n\n' "$cfg"
  printf '%s\n' "${pending[@]}"
  printf '\nfollowed by: nixos-rebuild switch\n'
  if [ "$ASSUME_YES" -eq 0 ]; then
    printf '\nApply them? [y/N]: '
    read -r reply
    case "$reply" in
      [yY]*) ;;
      *) info "Skipped; continuing with NIX_CONFIG only"; return 0 ;;
    esac
  fi

  backup="${cfg}.bak-$(date +%Y%m%d%H%M%S)"
  cp -a "$cfg" "$backup"

  # Insert before the file's final top-level `}`, i.e. the last closing brace in
  # column 0. awk rather than `sed i\` so the leading indentation survives.
  last="$(grep -n '^}' "$cfg" | tail -1 | cut -d: -f1)"
  if [ -z "$last" ]; then
    rm -f "$backup"
    info "Could not find the closing brace in $cfg -- using NIX_CONFIG only"
    return 0
  fi

  awk -v n="$last" -v ins="$(printf '%s\n' "${pending[@]}")" \
    'NR == n { print ins } { print }' "$cfg" >"${cfg}.tmp"
  cat "${cfg}.tmp" >"$cfg" # keep the original inode, owner and mode
  rm -f "${cfg}.tmp"

  info "Running nixos-rebuild switch (backup: $backup)"
  if ! nixos-rebuild switch; then
    cat "$backup" >"$cfg"
    die "nixos-rebuild switch failed; $cfg restored from $backup.
       Apply the changes by hand and re-run."
  fi
}

# ---------------------------------------------------------------------------
# Credentials
#
# A host with `users.mutableUsers = false` takes its password hashes from
# agenix, and agenix can only decrypt with an identity that already exists on
# the persisted volume -- modules/agenix.nix points identityPaths at
# ${persistDirectory}/... On a disk disko has just formatted there is none, so a
# plain disko -> nixos-install run produces a "successful" install where every
# account, root included, is locked. agenix and update-users-groups.pl only
# warn about it.
#
# Hence --host-keys, planted between disko and nixos-install further down, and
# --gen-keys to produce them in the first place. Ask the flake what the chosen
# host actually needs rather than hardcoding a host's layout here.
# ---------------------------------------------------------------------------

nix_eval() {
  nix eval --raw "${FLAKE}#nixosConfigurations.${HOST}.config.$1" --apply "$2" 2>/dev/null
}

MUTABLE_USERS=""
IDENTITY_PATHS=""
SECRET_USERS=""
NEEDS_KEYS=0

host_facts() {
  info "Asking the flake what $HOST needs"

  MUTABLE_USERS="$(nix_eval users.mutableUsers 'b: if b then "true" else "false"')" ||
    die "could not evaluate ${FLAKE}#nixosConfigurations.${HOST} --
       is '$HOST' a host in this flake?"

  # Empty for hosts without agenix (the attribute does not exist at all).
  IDENTITY_PATHS="$(nix_eval age.identityPaths 'ps: builtins.concatStringsSep "\n" ps' || true)"

  # Accounts whose password comes from a file agenix has to decrypt first.
  SECRET_USERS="$(nix_eval users.users 'us:
    builtins.concatStringsSep "\n" (
      builtins.filter (n: (us.${n}.hashedPasswordFile or null) != null) (builtins.attrNames us)
    )' || true)"

  if [ "$MUTABLE_USERS" = "false" ] && [ -n "$SECRET_USERS" ] && [ -n "$IDENTITY_PATHS" ]; then
    NEEDS_KEYS=1
  fi
}

# ---------------------------------------------------------------------------
# --gen-keys
#
# A fresh pair decrypts nothing on its own: the .age files are ciphertext for a
# fixed set of recipients, so the public half has to go into secrets/secrets.nix
# and `just rekey` has to run (on a machine holding a personal identity from
# userKeys) before these keys are worth anything. Hence the instructions at the
# end rather than a silent "done".
# ---------------------------------------------------------------------------

gen_keys() {
  outdir="${HOST_KEYS:-$HOST_KEYS_DEFAULT}"

  if [ -z "$IDENTITY_PATHS" ]; then
    info "$HOST declares no agenix identities -- nothing to generate"
    return 0
  fi

  mkdir -p "$outdir"
  chmod 0700 "$outdir"
  info "Generating host keys for $HOST in $outdir"

  while IFS= read -r identity; do
    [ -n "$identity" ] || continue
    base="${identity##*/}"

    # Only the host's own keys. A personal identity is yours, is already a
    # recipient of every secret, and a new one generated here would decrypt
    # nothing -- copy your own in by hand if you want it on the machine.
    case "$base" in
      ssh_host_*) ;;
      *)
        printf '    skipping %s (personal identity -- copy your own if you want it)\n' "$base"
        continue
        ;;
    esac

    dst="$outdir/$base"
    if [ -f "$dst" ]; then
      printf '    keeping existing %s\n' "$dst"
      continue
    fi

    case "$base" in
      *ed25519*) ssh-keygen -q -t ed25519 -N "" -C "root@$HOST" -f "$dst" ;;
      *rsa*) ssh-keygen -q -t rsa -b 4096 -N "" -C "root@$HOST" -f "$dst" ;;
      *)
        printf '    no key type known for %s -- skipping\n' "$base"
        continue
        ;;
    esac
    printf '    %s\n' "$dst"
  done <<<"$IDENTITY_PATHS"

  printf '\n  Public halves:\n\n'
  for pub in "$outdir"/*.pub; do
    [ -e "$pub" ] || continue
    printf '    %s\n' "$(ssh-keygen -lf "$pub")"
  done

  ed_pub="$outdir/ssh_host_ed25519_key.pub"
  [ -f "$ed_pub" ] || return 0
  update_secrets "$ed_pub" "$outdir"
}

# ---------------------------------------------------------------------------
# Put the new public key in secrets/secrets.nix, re-encrypt, commit.
#
# Two separate things, and only the first is editing text: listing a key in
# hostKeys does not give it anything to read. Every .age file is ciphertext for
# the recipients it was encrypted to, so `agenix -r` has to rewrite them all --
# using a personal identity from userKeys, which is the one thing this script
# cannot conjure. If none is present the keys are staged correctly but still
# decrypt nothing, and that is said loudly rather than left to be discovered
# after the install.
# ---------------------------------------------------------------------------

update_secrets() {
  ed_pub="$1"
  outdir="$2"
  secrets="$FLAKE/secrets/secrets.nix"
  key="$(cat "$ed_pub")"
  body="$(awk '{ print $2 }' "$ed_pub")"

  if [ ! -f "$secrets" ]; then
    info "No $secrets -- add $key to hostKeys by hand"
    return 0
  fi

  if grep -qF "$body" "$secrets"; then
    info "Already a recipient in $secrets"
  else
    # Backup goes to the staging directory, not next to the original: an
    # untracked .bak inside the repo is invisible to nix and just noise.
    cp -a "$secrets" "$outdir/secrets.nix.bak-$(date +%Y%m%d%H%M%S)"

    # Replace this host's stale entry if there is one, otherwise insert above
    # the template marker. Quoted entries only -- the example in the comment
    # above the list also ends in root@<host>".
    if awk -v tag="root@${HOST}\"" '
      /^[[:space:]]*"/ && index($0, tag) { found = 1 }
      END { exit !found }
    ' "$secrets"; then
      awk -v tag="root@${HOST}\"" -v new="    \"${key}\"" '
        /^[[:space:]]*"/ && index($0, tag) && !done { print new; done = 1; next }
        { print }
      ' "$secrets" >"${secrets}.tmp"
      info "Replaced the existing root@${HOST} entry in $secrets"
    elif grep -q '%HOST_KEY_TEMPLATE%' "$secrets"; then
      awk -v new="    \"${key}\"" '
        /%HOST_KEY_TEMPLATE%/ && !done { print new; done = 1 }
        { print }
      ' "$secrets" >"${secrets}.tmp"
      info "Added root@${HOST} to hostKeys in $secrets"
    else
      die "no root@${HOST} entry and no %HOST_KEY_TEMPLATE% marker in $secrets.
       Add this to hostKeys by hand:

         \"$key\""
    fi

    cat "${secrets}.tmp" >"$secrets"
    rm -f "${secrets}.tmp"
  fi

  # Re-encrypt. Needs a private key from userKeys; the justfile's default is
  # ~/.ssh/default_ed25519 and AGE_KEY_PATH overrides it.
  identity=""
  for candidate in "${AGE_KEY_PATH:-}" "$HOME/.ssh/default_ed25519" /root/.ssh/default_ed25519; do
    [ -n "$candidate" ] && [ -f "$candidate" ] && identity="$candidate" && break
  done

  if [ -z "$identity" ]; then
    cat <<EOF

  ----------------------------------------------------------------
   $secrets now lists this host, but the secrets themselves are
   still encrypted only to the old recipients -- so $HOST cannot read
   them yet, and installing now ends in a locked machine.

   No personal identity found (tried \$AGE_KEY_PATH, ~/.ssh/default_ed25519,
   /root/.ssh/default_ed25519). Either copy one here and re-run this, or
   from a machine that has one:

     just rekey && git commit -am 'nix: add $HOST host key' && git push
  ----------------------------------------------------------------

EOF
    return 0
  fi

  info "Re-encrypting every secret with $identity"
  (cd "$FLAKE/secrets" && nix run github:ryantm/agenix -- -r --identity "$identity") ||
    die "agenix -r failed. $secrets was updated; re-key by hand with:
       just rekey"

  # Nix only reads git-tracked files: an uncommitted rekey installs the old
  # ciphertext.
  if [ -d "$FLAKE/.git" ] && command -v git >/dev/null 2>&1; then
    git -C "$FLAKE" add secrets
    if git -C "$FLAKE" diff --cached --quiet -- secrets; then
      info "Nothing to commit in secrets/"
    else
      git -C "$FLAKE" -c user.email=install@localhost -c user.name=install \
        commit -q -m "nix: add $HOST host key and rekey secrets" ||
        die "could not commit secrets/ (nix needs it committed)"
      info "Committed secrets/ -- push it if this repo lives elsewhere too"
    fi
  fi

  info "Ready. Install with: sudo ./install.sh --host $HOST --disk /dev/<disk>"
}

# ---------------------------------------------------------------------------
# Preparation modes stop here -- neither of them touches a disk.
# ---------------------------------------------------------------------------

if [ "$MODE_SETUP" -eq 1 ]; then
  prepare_installer_system
fi

if [ "$MODE_GEN_KEYS" -eq 1 ]; then
  host_facts
  gen_keys
fi

if [ "$MODE_INSTALL" -eq 0 ]; then
  info "Done. Nothing was installed -- re-run without --setup/--gen-keys for that."
  exit 0
fi

# ---------------------------------------------------------------------------
# Everything below this line is the real install.
# ---------------------------------------------------------------------------

if ! nix --extra-experimental-features nix-command config show experimental-features 2>/dev/null |
  grep -qw flakes; then
  info "Flakes are not enabled system-wide -- using NIX_CONFIG for this run.
    './install.sh --setup' makes it permanent (and enables git-lfs)."
fi

host_facts

# Pick up what --gen-keys left behind, so the usual path needs no --host-keys.
if [ "$NEEDS_KEYS" -eq 1 ] && [ -z "$HOST_KEYS" ] && [ -d "$HOST_KEYS_DEFAULT" ]; then
  HOST_KEYS="$HOST_KEYS_DEFAULT"
  info "Using $HOST_KEYS (default for $HOST); --host-keys overrides it"
fi

if [ "$NEEDS_KEYS" -eq 1 ] && [ -z "$HOST_KEYS" ]; then
  die "$HOST sets users.mutableUsers = false and decrypts its password hashes
       with agenix, so it needs the private identities. Without them the
       install finishes with every account locked, sudo included.

       Nothing in $HOST_KEYS_DEFAULT, and no --host-keys DIR given. Generate
       them:

         ./install.sh --gen-keys --host $HOST

       or point --host-keys at a directory holding at least one of these,
       named by basename:

$(sed 's|^|         |' <<<"$IDENTITY_PATHS")

       Wherever they come from, they are copied to those paths -- the ones
       $HOST's own agenix module declares. See ## Installation in README.md."
fi

# Validate the key material before anything destructive happens.
PLANT=0
if [ -n "$HOST_KEYS" ] && [ -n "$IDENTITY_PATHS" ]; then
  [ -d "$HOST_KEYS" ] || die "--host-keys '$HOST_KEYS' is not a directory"

  MATCHED=""
  while IFS= read -r identity; do
    [ -n "$identity" ] || continue
    [ -f "$HOST_KEYS/${identity##*/}" ] || continue
    MATCHED="${MATCHED}${identity}"$'\n'
  done <<<"$IDENTITY_PATHS"

  [ -n "$MATCHED" ] ||
    die "none of the identities $HOST expects were found in $HOST_KEYS.
       Expected file names:

$(sed 's|.*/|         |' <<<"$IDENTITY_PATHS")"

  PLANT=1

  # A key that is not listed in secrets/secrets.nix cannot decrypt anything --
  # the .age files are ciphertext for a fixed set of recipients. Cheap to check,
  # and catches "generated a fresh pair and forgot to just rekey".
  SECRETS="$FLAKE/secrets/secrets.nix"
  if [ -f "$SECRETS" ] && command -v ssh-keygen >/dev/null 2>&1; then
    RECIPIENT=0
    while IFS= read -r identity; do
      [ -n "$identity" ] || continue
      src="$HOST_KEYS/${identity##*/}"
      pub="$(ssh-keygen -y -f "$src" </dev/null 2>/dev/null | awk '{ print $2 }')" || true
      [ -n "$pub" ] || continue
      grep -qF "$pub" "$SECRETS" && RECIPIENT=1
    done <<<"$MATCHED"

    if [ "$RECIPIENT" -eq 0 ]; then
      printf '\n'
      printf 'warning: no key in %s appears in %s.\n' "$HOST_KEYS" "$SECRETS"
      printf 'agenix will not be able to decrypt hashed_password.age with these,\n'
      printf 'and the install will finish with every account locked. Add the public\n'
      printf 'half to secrets/secrets.nix, run `just rekey`, and commit first.\n'
      if [ "$ASSUME_YES" -eq 0 ]; then
        printf '\nContinue anyway? [y/N]: '
        read -r reply
        case "$reply" in [yY]*) ;; *) die "aborted" ;; esac
      fi
    fi
  fi
elif [ -n "$HOST_KEYS" ]; then
  info "$HOST declares no agenix identities -- ignoring --host-keys"
fi

# ---------------------------------------------------------------------------
# Pick the target disk
# ---------------------------------------------------------------------------

if [ -z "$DISK" ]; then
  info "Available disks"
  lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,TYPE | grep -E 'disk|NAME'
  printf '\nTarget disk (e.g. /dev/nvme0n1): '
  read -r DISK
fi

[ -b "$DISK" ] || die "'$DISK' is not a block device"

# Refuse to eat the installer we are running from.
ROOT_SRC="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
ISO_SRC="$(findmnt -n -o SOURCE /iso 2>/dev/null || true)"
for mounted in "$ROOT_SRC" "$ISO_SRC"; do
  [ -n "$mounted" ] || continue
  case "$mounted" in
    "$DISK"*) die "'$DISK' is backing the running installer ($mounted). Refusing." ;;
  esac
done

DISK_SIZE="$(lsblk -dn -o SIZE "$DISK")"
DISK_MODEL="$(lsblk -dn -o MODEL "$DISK" | tr -s ' ')"

# ---------------------------------------------------------------------------
# The disk name lives in profiles/settings.nix, not in this script. Keep them
# in sync rather than silently partitioning something the flake does not expect.
# ---------------------------------------------------------------------------

DISK_SHORT="${DISK#/dev/}"
SETTINGS="$FLAKE/profiles/settings.nix"
CONFIGURED=""

if [ -f "$SETTINGS" ]; then
  CONFIGURED="$(awk -v h="$HOST" '
    $1 == h && $2 == "=" { inblock = 1 }
    inblock && $1 == "device" { gsub(/[";]/, "", $3); print $3; exit }
  ' "$SETTINGS")"
fi

if [ -n "$CONFIGURED" ] && [ "$CONFIGURED" != "$DISK_SHORT" ]; then
  printf '\n'
  printf 'profiles/settings.nix has %s.device = "%s", but you chose "%s".\n' \
    "$HOST" "$CONFIGURED" "$DISK_SHORT"
  printf 'The flake decides what disko formats, so this file must be updated\n'
  printf 'and committed before installing.\n'
  printf 'Note: the rewrite is not scoped to one host -- every host set to "%s"\n' "$CONFIGURED"
  printf 'is repointed. Check the diff if that matters.\n'
  if [ "$ASSUME_YES" -eq 0 ]; then
    printf '\nUpdate it now? [y/N]: '
    read -r reply
    case "$reply" in [yY]*) ;; *) die "aborted: fix $SETTINGS by hand and re-run" ;; esac
  fi
  sed -i "s|^\(\s*device = \)\"$CONFIGURED\";|\1\"$DISK_SHORT\";|" "$SETTINGS"
  grep -q "\"$DISK_SHORT\"" "$SETTINGS" || die "failed to update $SETTINGS"
  if [ -d "$FLAKE/.git" ]; then
    git -C "$FLAKE" add profiles/settings.nix
    git -C "$FLAKE" -c user.email=install@localhost -c user.name=install \
      commit -q -m "nix: point $HOST at $DISK_SHORT" ||
      die "could not commit the settings change (nix needs it committed)"
    info "Committed the device change so the flake picks it up"
  fi
fi

# ---------------------------------------------------------------------------
# Confirm
# ---------------------------------------------------------------------------

cat <<EOF

  ----------------------------------------------------------------
   host    : $HOST
   flake   : $FLAKE
   disk    : $DISK  ($DISK_SIZE $DISK_MODEL)
   keys    : ${HOST_KEYS:-none needed}

   EVERYTHING ON $DISK WILL BE DESTROYED.
  ----------------------------------------------------------------
EOF

if [ "$ASSUME_YES" -eq 0 ]; then
  printf "\nType 'yes' to continue: "
  read -r confirm
  [ "$confirm" = "yes" ] || die "aborted"
fi

# ---------------------------------------------------------------------------
# Partition, format, mount
# ---------------------------------------------------------------------------

NIX="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

info "Partitioning and formatting with disko"
# shellcheck disable=SC2086
$NIX run github:nix-community/disko -- \
  --mode disko --flake "${FLAKE}#${HOST}"

mountpoint -q /mnt || die "disko finished but /mnt is not mounted"

# ---------------------------------------------------------------------------
# Plant the agenix identities on the persisted volume, before the first
# activation runs. This is the step whose absence locks you out.
# ---------------------------------------------------------------------------

if [ "$PLANT" -eq 1 ]; then
  info "Planting agenix identities on the persisted volume"
  planted=0
  while IFS= read -r identity; do
    [ -n "$identity" ] || continue
    src="$HOST_KEYS/${identity##*/}"
    dst="/mnt${identity}"
    dstdir="${dst%/*}"

    mkdir -p "$dstdir"
    # A personal identity under ~/.ssh has to be readable by its owner once
    # impermanence bind-mounts it into $HOME; host keys under /etc/ssh stay
    # root-owned.
    case "$identity" in
      */.ssh/*)
        chmod 0700 "$dstdir"
        chown 1000:100 "$dstdir" || true
        ;;
      *) chmod 0755 "$dstdir" ;;
    esac

    install -Dm0600 "$src" "$dst"
    [ -f "${src}.pub" ] && install -Dm0644 "${src}.pub" "${dst}.pub" || true
    case "$identity" in
      */.ssh/*) chown 1000:100 "$dst" "${dst}.pub" 2>/dev/null || true ;;
    esac

    printf '    %s\n' "$dst"
    planted=$((planted + 1))
  done <<<"$MATCHED"

  [ "$planted" -gt 0 ] || die "planted no identities -- refusing to install into a lockout"
fi

if [ "$NEEDS_KEYS" -eq 1 ] && [ "$PLANT" -eq 0 ]; then
  die "internal: $HOST needs identities but none were planted"
fi

# ---------------------------------------------------------------------------
# Give the build somewhere real to work. The installer's Nix store is a tmpfs
# in RAM, and this closure (Hyprland, a full home-manager profile) will exhaust
# it on a machine without a lot of memory.
# ---------------------------------------------------------------------------

for vg in root_vg main_vg; do
  if [ -e "/dev/$vg/swap" ]; then
    info "Enabling swap on the target so the build is not RAM-bound"
    swapon "/dev/$vg/swap" || true
    break
  fi
done

mkdir -p /mnt/tmp

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

info "Running nixos-install (this is the slow part)"
TMPDIR=/mnt/tmp nixos-install --flake "${FLAKE}#${HOST}" --no-root-passwd

# ---------------------------------------------------------------------------
# Did the credentials actually land? On an impermanent host /etc/shadow is on
# the tmpfs root and is rewritten at every activation, so this only proves the
# first one worked -- which is exactly the activation that would have silently
# locked the machine. Better to find out now than after the reboot.
# ---------------------------------------------------------------------------

if [ "$NEEDS_KEYS" -eq 1 ] && [ -f /mnt/etc/shadow ]; then
  LOCKED=""
  while IFS= read -r account; do
    [ -n "$account" ] || continue
    hash="$(awk -F: -v u="$account" '$1 == u { print $2 }' /mnt/etc/shadow)"
    case "$hash" in
      \$*) ;;
      *) LOCKED="$LOCKED $account" ;;
    esac
  done <<<"$SECRET_USERS"

  if [ -n "$LOCKED" ]; then
    die "installed, but these accounts have no usable password hash:$LOCKED

       agenix could not decrypt hashed_password.age. Do NOT reboot yet -- fix
       it from here, where /mnt is still mounted:

         1. confirm the identities are in place:  ls -l /mnt/persist/etc/ssh
         2. confirm their public halves are in secrets/secrets.nix (just rekey)
         3. re-run activation:
              nixos-enter --root /mnt -- /run/current-system/bin/switch-to-configuration switch

       Rebooting now leaves you with console and sudo locked; SSH public-key
       auth would still work."
  fi
  info "Password hashes are in place for: $(tr '\n' ' ' <<<"$SECRET_USERS")"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

cat <<EOF

==> Done.

EOF

if [ "$NEEDS_KEYS" -eq 1 ]; then
  cat <<EOF
    Log in as 'mbenevides'. The password is the one in
    secrets/hashed_password.age, decrypted at every activation by the keys
    planted in step above -- 'passwd' will NOT stick, because the root
    filesystem is a tmpfs. Change it in the secret, not on the machine.

    Reboot with:  reboot

EOF
else
  cat <<EOF
    Log in as 'mbenevides' with the password 'test'.

    That password is declared in hosts/$HOST/configuration.nix and is
    re-applied on every activation -- the root filesystem is a tmpfs, so
    'passwd' will NOT stick. Change it in the config, not on the machine.

    Reboot with:  reboot

EOF
fi
