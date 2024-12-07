# NixOS Configuration

My NixOS configuration files, used in my personal systems and work machines.

## TODO List

   - [X] Use home-manager for user-related configurations
   - [X] Integration with Nix-flakes
   - [X] Integration with the [impermanence](https://github.com/nix-community/impermanence) module
   - [X] Add a wayland-based WM (`hyprland`)
   - [X] Declarative styling with [stylix](https://github.com/danth/stylix)
   - [ ] Integration with one of the following secret management tools:
     - :white_check_mark: [agenix](https://github.com/ryantm/agenix) 
     - :x: [sops-nix](https://github.com/Mic92/sops-nix)
   - [ ] Declarative disk partitions with [disko](https://github.com/nix-community/disko) 
   - [ ] Add this entire config into CI

## How to use it?

   - Clone this repo
   - Generate some `agenix` files:
```shell
    RULES="./secrets/secrets.nix" nix run github:ryantm/agenix -- -e "defaults.json.age"
    # or
    chmod 700 ./mk_secrets.sh
    ./mk_secrets.sh
```
   - Pick a definition in the flake.nix
   - Build it

```shell
  sudo nixos-rebuild switch --flake .#caladan
  # or
  sudo nixos-rebuild switch --flake .#euclid
```

## Why should I use it?

You probably shouldn't.

## Screenshots

- Neovim

![Neovim01](./docs/neovim.png)

