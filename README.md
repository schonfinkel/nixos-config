# NixOS Configuration

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

My NixOS configuration files, used in my personal systems and work machines.

## TODO List

   - [X] Use home-manager for user-related configurations
   - [X] Integration with Nix-flakes
   - [X] Integration with the [impermanence](https://github.com/nix-community/impermanence) module
   - [X] Add a wayland-based WM (`hyprland`)
   - [X] Declarative styling with [stylix](https://github.com/danth/stylix)
   - [X] Integration with one of the following secret management tools:
     - [agenix](https://github.com/ryantm/agenix) 
     - [sops-nix](https://github.com/Mic92/sops-nix)
   - [X] Modurize configuration with `nix` modules
   - [ ] Add this entire config into CI
   - [ ] Declarative disk partitions with [disko](https://github.com/nix-community/disko) 

## Development Shell

```shell
  direnv allow
  # or
  nix develop --impure
```

## How to use it?

   - Clone this repo
   - Pick a definition in the flake.nix
   - Build it

```shell
  sudo nixos-rebuild switch --flake .#caladan
  # or
  sudo nixos-rebuild switch --flake .#euclid
```

## Why should I use it?

You probably shouldn't.

