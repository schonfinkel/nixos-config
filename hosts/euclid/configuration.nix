# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # ./persist.nix

    # Custom Modules
    ../../modules

    # Virtualisation
    ../../virtualisation/docker.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "systemd.log_level=debug"
    "systemd.log_target=kmsg"
    "rd.systemd.log_level=debug"
  ];

  boot.kernel.sysctl = {
    "kernel.sysrq" = 128;
  };

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
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  #services.xserver.displayManager.gdm.enable = true;
  #services.xserver.desktopManager.gnome.enable = true;
  services.libinput.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
    };
  };

  # On the Brazilian ThinkPad keyboard the `/ ?` key sits where right-Ctrl is on
  # other layouts, and the kernel reports it as KEY_RIGHTCTRL (keycode 97, as
  # `showkey` confirms). The br(thinkpad) XKB variant papers over that by giving
  # <RCTL> the slash/question symbols, which is enough for anything that goes
  # through the keymap -- but not for anything that looks at the physical key.
  # Ghostty sees `control_right`, concludes Ctrl is held, and encodes Shift+key
  # as Ctrl+? (DEL) instead of typing `?`. No Ghostty keybind can undo that: the
  # variant also drops <RCTL> from the Control modmap, so there is no Ctrl
  # modifier for a `ctrl+...` trigger to match.
  #
  # So fix it at the source: report the key as KEY_RO, which is where ABNT2 puts
  # `/ ?` anyway (<AB11>), and every layer above agrees. Scancode 0x9d is
  # right-Ctrl as atkbd reports it -- set 1's e0 prefix is folded into the high
  # bit, so 0x1d|0x80, not the 0xe01d you would write for a USB keyboard. The
  # DMI match keeps this to the built-in keyboard, so an external one is
  # untouched and keeps a working right-Ctrl.
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:bvn*:bvr*:bd*:svnLENOVO:pn*:pvrThinkPadL13Gen1*
     KEYBOARD_KEY_9d=ro
  '';

  # Single source of truth for the keyboard: SDDM and console.useXkbConfig read
  # this directly, and homeModules.hyprland.xkb defaults to it (Hyprland has its
  # own input block). This machine only ever types on its own keyboard, so there
  # is no second layout and no grp:* toggle here.
  #
  # The thinkpad variant stays as a belt-and-braces fallback: with the remap
  # above the key already arrives as <AB11>, which plain `br` maps to
  # slash/question. Drop the variant -- and get right-Ctrl back on external
  # keyboards -- once the remap has been confirmed on real hardware.
  services.xserver = {
    xkb.layout = "br";
    xkb.variant = "thinkpad";
    xkb.options = "ctrl:nocaps";
    videoDrivers = [ "modesetting" ];
  };

  hardware.graphics.enable = true;
  fonts.fontconfig.antialias = true;
  fonts.fontconfig.hinting.enable = true;
  fonts.fontconfig.subpixel.rgba = "rgb";

  programs.steam.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  users.mutableUsers = false;
  users.users = {
    root.hashedPasswordFile = config.age.secrets.hashed_password.path;
    mbenevides = {
      uid = 1000;
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.hashed_password.path;
      extraGroups = [
        "audio"
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
  };

  hostModules.audio = {
    enable = true;
  };

  hostModules.commons = {
    enable = true;
    hostName = "euclid";
  };

  hostModules.hyprland = {
    enable = true;
  };

  hostModules.impermanence = {
    enable = true;
    username = "mbenevides";
  };

  hostModules.ssh = {
    enable = true;
    allowUsers = [ "mbenevides" ];
  };

  hostModules.themes = {
    enable = true;
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
