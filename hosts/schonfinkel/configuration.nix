# "schonfinkel" -- same host modules as caladan, but with disko-managed disks
# and a genuinely ephemeral root. Unencrypted: the disk holds nothing worth a
# passphrase prompt at every boot. Switching to full-disk LUKS later is a matter
# of setting `profile = "luks"` below and re-running `disko --mode disko`
# (destructive).
#
# Disk layout lives in profiles/disko/ext4_ephemeral.nix; device name and swap
# size in profiles/settings.nix.
#
# Installing this host is order-sensitive -- the host keys have to be on
# /persist before nixos-install, or every account comes up locked. `install.sh`
# handles that; see ## Installation in the top-level README.md.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Fallback login hash, used *only* when agenix cannot decrypt
  # hashed_password.age. For immutable users NixOS resolves
  # `initialHashedPassword` into `hashedPassword`, and
  # update-users-groups.pl overwrites that from `hashedPasswordFile` only when
  # the file actually exists -- otherwise it just warns. So the agenix secret
  # always wins when it works, and this catches the broken case instead of
  # leaving every account locked.
  #
  # Deliberately null: this repository is public, and a hash committed here is
  # offline-crackable by anyone. Populate it if you make the repo private:
  #   mkpasswd -m yescrypt
  rescueHashedPassword = null;
in

{
  imports = [
    ./hardware-configuration.nix

    # Custom Modules
    ../../modules
    # disko is not part of ../../modules/default.nix -- only hosts that manage
    # their disks declaratively pull it in.
    ../../modules/disko.nix

    # Virtualisation
    ../../virtualisation/docker.nix
    ../../virtualisation/waydroid.nix
  ];

  # Bootloader (UEFI). profiles/disko/ext4_ephemeral.nix also lays down a BIOS
  # boot partition, so switching to GRUB on a legacy machine stays possible.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.tmp.cleanOnBoot = true;

  # https://github.com/nix-community/nixos-generators?tab=readme-ov-file#cross-compiling
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernel.sysctl = {
    "kernel.sysrq" = 128;
  };

  boot.initrd.systemd.enable = true;

  # impermanence builds its bind mounts in stage 1, so every persistence root
  # has to be mounted by then. /persist additionally carries the agenix identity
  # and the SSH host keys.
  fileSystems."/persist".neededForBoot = true;

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
    (lib.filterAttrs (_: lib.isType "flake")) inputs
  );

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = [ "/etc/nix/path" ];

  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  # Nixpkgs
  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };

  # Hardware
  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # GPU config, same shape as caladan.
  hardware.nvidia = {
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  services.displayManager = {
    sddm = {
      enable = true;
    };
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
    dpi = 180;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  fonts.fontconfig.antialias = true;
  fonts.fontconfig.hinting.enable = true;
  fonts.fontconfig.subpixel.rgba = "rgb";

  programs.steam.enable = true;
  programs.noisetorch.enable = true;

  users.mutableUsers = false;
  users.users = {
    root = {
      hashedPasswordFile = config.age.secrets.hashed_password.path;
      initialHashedPassword = lib.mkIf (rescueHashedPassword != null) rescueHashedPassword;
    };
    mbenevides = {
      uid = 1000;
      isNormalUser = true;
      description = "mbenevides";
      hashedPasswordFile = config.age.secrets.hashed_password.path;
      initialHashedPassword = lib.mkIf (rescueHashedPassword != null) rescueHashedPassword;
      extraGroups = [
        "audio"
        "dialout"
        "disk"
        "docker"
        "input"
        "networkmanager"
        "tty"
        "video"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcbZwcStUfn6HFjyWdUb1jZqzQMf3JWeIj3RgP8nKwDatHSVB0GkvSETBiJ+bfbGKK1bacusqfsiN3b2niytDgnWMtKB4tMgvGUn5AEqRBtI5zDrnPU1T7edDCjI32QLBln/HlcfAHz+avN4YsW7iTWu25N/MSOQwBrKHLEQviGq9/j3Wu1pzxV2n2m32uUATFEKLf3sLCdsOWm1r+HlsXOcukUZnRhLc9O2ZVoWtDHo72iOzVY6rlRBoHvoUxw6A8k/jZWb1ospvjOLsjZuAZaDSjcE6iM0nXQSdhgGPSgeCTofOgteYoovA4XlK4aNomuTI3OPLr9P9SLC0qJHidvLIGQYWyMiwdeDJESbY2PFUNCi5VffwEUPYh8sp3E8EwjGDvSCygu4fU7vqaOi3OEziwg2ff89CdVr7k606LYmRF3dR+12Cp6XBOgUoaz+OzGn0Sr9HXw3GiF9xH/e1PL6mHwUT2NARB/mI64uY9JAi0/hrwkQsiIx1tf63qUDz/je9gk53wP7/GfWNoIeEkRzCz0QkEnxcMEoLjbTk56JFkmP0fpHDQ== (none)"
      ];
    };
  };

  # Enable Host modules
  hostModules.agenix = {
    enable = true;
    paths = [
      "/home/mbenevides/.ssh/default_ed25519"
    ];
    # luksKeyFile is only for the two-disk luks_multi profile, to hold the data
    # disk's second LUKS slot. Nothing here is encrypted, so it stays unset.
  };

  hostModules.audio = {
    enable = true;
  };

  hostModules.commons = {
    enable = true;
    hostName = "schonfinkel";
  };

  hostModules.disko = {
    enable = true;
    profile = "ext4_ephemeral";
    target = "schonfinkel";
  };

  hostModules.hyprland = {
    enable = true;
  };

  hostModules.impermanence = {
    enable = true;
    username = "mbenevides";
    # disko mounts the persist LV at /persist, not at the module's /nix/persist
    # default.
    persistDirectory = "/persist";
  };

  hostModules.ssh = {
    enable = true;
    allowUsers = [ "mbenevides" ];
  };

  hostModules.themes = {
    enable = true;
  };

  # See `man configuration.nix` or
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  # Do NOT change this after the initial install.
  system.stateVersion = "26.05";
}
