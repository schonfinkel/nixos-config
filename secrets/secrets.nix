let
  # My public keys. These can decrypt every secret from any machine.
  userKeys = [
    # GPG-managed ssh key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcbZwcStUfn6HFjyWdUb1jZqzQMf3JWeIj3RgP8nKwDatHSVB0GkvSETBiJ+bfbGKK1bacusqfsiN3b2niytDgnWMtKB4tMgvGUn5AEqRBtI5zDrnPU1T7edDCjI32QLBln/HlcfAHz+avN4YsW7iTWu25N/MSOQwBrKHLEQviGq9/j3Wu1pzxV2n2m32uUATFEKLf3sLCdsOWm1r+HlsXOcukUZnRhLc9O2ZVoWtDHo72iOzVY6rlRBoHvoUxw6A8k/jZWb1ospvjOLsjZuAZaDSjcE6iM0nXQSdhgGPSgeCTofOgteYoovA4XlK4aNomuTI3OPLr9P9SLC0qJHidvLIGQYWyMiwdeDJESbY2PFUNCi5VffwEUPYh8sp3E8EwjGDvSCygu4fU7vqaOi3OEziwg2ff89CdVr7k606LYmRF3dR+12Cp6XBOgUoaz+OzGn0Sr9HXw3GiF9xH/e1PL6mHwUT2NARB/mI64uY9JAi0/hrwkQsiIx1tf63qUDz/je9gk53wP7/GfWNoIeEkRzCz0QkEnxcMEoLjbTk56JFkmP0fpHDQ== (none)"
    # normal ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5HDsDVFBscGYZ7Tb0dkx9bUUxDnEIB3s+T4pbpvc3D default"
  ];

  # Per-host SSH *host* keys.
  #
  # Listing a machine here is what lets it decrypt its own secrets on the very
  # first boot, instead of depending on a personal key having been copied onto
  # /persist by hand. Without this, a fresh impermanent host has no readable
  # identity during its first activation, agenix cannot decrypt
  # hashed_password.age, and -- with users.mutableUsers = false -- every account
  # ends up locked.
  #
  # To add one: `./install.sh --gen-keys --host <host>`. It generates the pair,
  # writes the *public* half into the list below, runs the rekey, commits, and
  # leaves the private half staged for the install to plant on /persist. Doing
  # it by hand means the same four steps in that order.
  hostKeys = [
    # schonfinkel = "ssh-ed25519 AAAA... root@schonfinkel";
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbECQT183cXRGC4ZiPDoXgxJnFT1cIhW1KdwMET4nN+ root@schonfinkel"
    # %HOST_KEY_TEMPLATE% -- do not remove. `install.sh --gen-keys` rewrites this
    # list: an existing "root@<host>" entry is replaced in place, otherwise the
    # new key is inserted directly above this marker.
  ];

  keys = userKeys ++ hostKeys;
in
{
  "hashed_password.age".publicKeys = keys;
  # Key file that unlocks the secondary data disk on a two-disk LUKS host
  # (profiles/disko/luks_multi.nix). See hostModules.agenix.luksKeyFile. No host
  # currently sets it.
  "luks_data.age".publicKeys = keys;
}
