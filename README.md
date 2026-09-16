# NixOS Configuration

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)
[![[QEMU] Image Build](https://github.com/schonfinkel/nixos-config/actions/workflows/qemu_build.yml/badge.svg)](https://github.com/schonfinkel/nixos-config/actions/workflows/qemu_build.yml)

My NixOS configuration files, used in my personal systems and work machines.

## TODO List

   - [X] Use home-manager for user-related configurations
   - [X] Integration with Nix-flakes
   - [X] Integration with the [impermanence](https://github.com/nix-community/impermanence) module
   - [X] Add a wayland-based WM (`hyprland` + `noctalia-shell`)
   - [X] Declarative styling with [stylix](https://github.com/danth/stylix)
   - [X] Integration with one of the following secret management tools:
     - [agenix](https://github.com/ryantm/agenix) 
     - [sops-nix](https://github.com/Mic92/sops-nix)
   - [X] Modurize configuration with `nix` modules
   - [X] Add QEMU-based builds for CI
   - [X] Declarative disk partitions with [disko](https://github.com/nix-community/disko) 

## Development Shell

```shell
  direnv allow
  # or
  nix develop --impure
```

## How to use it?

- Clone this repo.
- Pick a host.
- Run `nixos-rebuild`.

```shell
  sudo nixos-rebuild switch --flake .#schonfinkel
  # or
  sudo nixos-rebuild switch --flake .#euclid
```

## Installation

1. Onto a fresh machine, with `install.sh`. 
2. Boot the NixOS installer in UEFI mode, get networking up, clone this repo, then:

    ```shell
    # Make the machine you are running from able to drive this flake
    #
    # Adds nix.settings.experimental-features + programs.git.lfs.enable to
    # /etc/nixos/configuration.nix and rebuilds, skip it on the live ISO,
    # which has no /etc/nixos, the script falls back to NIX_CONFIG.
    sudo ./install.sh --setup
    ```

    - This step needs one of the personal keys from `userKeys` (`~/.ssh/default_ed25519`, or `AGE_KEY_PATH`) to re-encrypt with, nothing else can read the existing `.age` files. 
    - Without it the key is still added to `secrets/secrets.nix`, and the script says plainly that `just rekey` has to happen elsewhere before installing. 

3. (Optional) Only for hosts whose passwords come from agenix (i.e. `schonfinkel`):
    ```shell
    # Generates its SSH host keys, adds the public half to hostKeys in
    # secrets/secrets.nix, re-encrypts every secret to it, and commits
    ./install.sh --gen-keys --host schonfinkel
    ```

    - The `%HOST_KEY_TEMPLATE%` marker in `secrets/secrets.nix` is what the rewrite anchors on; an entry that already exists for the host is replaced in place instead.
    - `--gen-keys` writes to `/tmp/<host>-keys` and step 3 reads it back from there, so neither command needs a path (`--host-keys DIR` overrides). 
    - The keys are copied onto the persisted volume between partitioning and `nixos-install`, to the paths the host's own agenix module declares (`config.age.identityPaths`, `/persist/etc/ssh/...` on the impermanent hosts). 
    - That step is what keeps a `users.mutableUsers = false` host from booting with every account locked: on a freshly formatted disk agenix has no identity, cannot decrypt `hashed_password.age`, and only warns about it. 
    - The script refuses to install without the keys, and checks `/mnt/etc/shadow` afterwards before declaring success.

4. Final, run the install script.

    ```shell
    # THIS ERASES THE DISK
    sudo ./install.sh --host schonfinkel --disk /dev/nvme0n1
    ```

    - `./install.sh --help` lists the rest. The disk layout comes from `profiles/disko/<profile>.nix` and `profiles/settings.nix`.
    - The installer only formats what the flake declares, and changing `hostModules.disko.profile` later needs another `disko --mode disko` run (destructive), not a rebuild.

## Why should I use it?

You probably shouldn't.

