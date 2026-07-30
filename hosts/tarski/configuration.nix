# "tarski" -- the go-to host for standing up a new machine quickly.
#
# Deliberately minimal: no agenix, no secrets to bootstrap. It exists to get a
# usable,
# bootable Hyprland desktop onto unknown hardware in one command, not to be a
# finished daily driver. Once the machine is up and you know what it is, copy it
# into its own host under hosts/ and grow from there.
#
# It does run disko + impermanence: the root is a tmpfs and only what
# modules/impermanence.nix declares survives a reboot.
#
# Install with ./install.sh, e.g.
#   sudo ./install.sh --disk /dev/nvme0n1
#
# Deliberately absent:
#   - agenix        needs an identity on the target before first boot, which is
#                   the opposite of a quick install. `mbenevides` gets a plain
#                   initialPassword instead.
#
# Present although it is not "minimal": stylix. home/hyprland.nix reads
# config.stylix.base16Scheme and config.lib.stylix.colors to colour Hyprland,
# waybar and hyprlock, so the WM simply does not evaluate without it.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # No ./hardware-configuration.nix on purpose -- this host targets unknown
    # machines, so the hardware bits below are deliberately generic. Run
    # `nixos-generate-config --no-filesystems` after first boot if the machine
    # needs anything specific.
    #
    # Modules are listed individually rather than importing ../../modules,
    # because modules/agenix.nix defines `age.*` and would require the agenix
    # NixOS module to be present even with hostModules.agenix.enable = false --
    # `mkIf` defers the value, not the option lookup. Same pattern as peano.
    ../../modules/audio.nix
    ../../modules/commons.nix
    ../../modules/disko.nix
    ../../modules/hyprland.nix
    ../../modules/impermanence.nix
    ../../modules/ssh.nix
    ../../modules/themes.nix
  ];

  # Bootloader (UEFI). profiles/disko/ext4_ephemeral.nix also lays down a BIOS
  # boot partition, so switching to GRUB on a legacy machine stays possible.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Generic hardware. Broad enough to boot on most things; the wrong kvm module
  # simply fails to load.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod"
    "virtio_pci"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [
    "kvm-intel"
    "kvm-amd"
  ];

  # impermanence builds its bind mounts in stage 1, so /persist has to be
  # mounted by then -- it also holds the SSH host keys.
  fileSystems."/persist".neededForBoot = true;

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;

  # Open-source drivers only -- we do not know what GPU this machine has.
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager.sddm.enable = true;

  nixpkgs.config.allowUnfree = true;

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
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };

  # Immutable on purpose. The root filesystem is a tmpfs, so /etc/shadow is
  # recreated on every boot -- a `passwd` change would silently revert. Setting
  # it declaratively means the password is re-applied identically each
  # activation instead.
  #
  # This is a throwaway bootstrap credential. SSH is public-key only
  # (PasswordAuthentication = false in modules/ssh.nix), so it is console-only
  # exposure, but change it before the machine becomes anything permanent.
  users.mutableUsers = false;
  users.users.mbenevides = {
    uid = 1000;
    isNormalUser = true;
    description = "mbenevides";
    initialPassword = "test";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "tty"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKStRI4iiTc6nTPKc0SPjHq79psNR5q733InvuHFAT0BHIiKWmDHeLS5jCep/MMrKa1w9qCt3bAnJVyu33+oqISx/5PzDBikiBBtBD6irovJx9dVvkjWkQLcbZwcStUfn6HFjyWdUb1jZqzQMf3JWeIj3RgP8nKwDatHSVB0GkvSETBiJ+bfbGKK1bacusqfsiN3b2niytDgnWMtKB4tMgvGUn5AEqRBtI5zDrnPU1T7edDCjI32QLBln/HlcfAHz+avN4YsW7iTWu25N/MSOQwBrKHLEQviGq9/j3Wu1pzxV2n2m32uUATFEKLf3sLCdsOWm1r+HlsXOcukUZnRhLc9O2ZVoWtDHo72iOzVY6rlRBoHvoUxw6A8k/jZWb1ospvjOLsjZuAZaDSjcE6iM0nXQSdhgGPSgeCTofOgteYoovA4XlK4aNomuTI3OPLr9P9SLC0qJHidvLIGQYWyMiwdeDJESbY2PFUNCi5VffwEUPYh8sp3E8EwjGDvSCygu4fU7vqaOi3OEziwg2ff89CdVr7k606LYmRF3dR+12Cp6XBOgUoaz+OzGn0Sr9HXw3GiF9xH/e1PL6mHwUT2NARB/mI64uY9JAi0/hrwkQsiIx1tf63qUDz/je9gk53wP7/GfWNoIeEkRzCz0QkEnxcMEoLjbTk56JFkmP0fpHDQ== (none)"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5HDsDVFBscGYZ7Tb0dkx9bUUxDnEIB3s+T4pbpvc3D default"
    ];
  };

  # Host modules -- the minimum for a usable desktop.
  hostModules.audio = {
    enable = true;
  };

  hostModules.commons = {
    enable = true;
    hostName = "tarski";
  };

  hostModules.disko = {
    enable = true;
    profile = "ext4_ephemeral";
    target = "tarski";
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

  # Required by home/hyprland.nix, which is built on stylix colours.
  hostModules.themes = {
    enable = true;
  };

  system.stateVersion = "26.05";
}
