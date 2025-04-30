# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, inputs, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./persist.nix
      # Pre-configured Services
      ../../services/journald.nix
      ../../services/localization.nix
      ../../services/pipewire.nix

      ../../services/hyprland.nix
      ../../services/theme.nix

      # Virtualisation
      ../../virtualisation/docker.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    "kernel.sysrq" = 128;
  }; 

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = [ "/etc/nix/path" ];

  environment.etc =
    lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

  # Nixpkgs
  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };

  networking.hostName = "euclid"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

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

  #programs.hyprland = {
  #  enable = true;
  #  # set the flake package
  #  package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  #  # make sure to also set the portal package, so that they are in sync
  #  portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  #};

  services.xserver = {
    xkb.layout = "br(thinkpad),us";
    xkb.options = "ctrl:nocaps,";
    videoDrivers = ["intel"];
  };

  hardware.graphics.enable = true;
  fonts.fontconfig.antialias = true;
  fonts.fontconfig.hinting.enable = true;
  #fonts.fontconfig.subpixel.rgba = "rgb";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  users.mutableUsers = false;
  users.users = {
    # root.hashedPassword = lib.removeSuffix "\n" (builtins.readFile "/nix/persist/var/users/root");
    #root.password = lib.removeSuffix "\n" (builtins.readFile "/nix/persist/var/users/root");
    root.hashedPassword = "$y$j9T$6zLPFDkAeDgRk2Aw4JUTL1$adKhB4NX2bJ3hn4jHLiNd40plkUr0Dmy3GaRzVacGa.";
    mbenevides = {
      uid = 1000;
      isNormalUser = true;
      #password = "test";
      hashedPassword = "$y$j9T$6zLPFDkAeDgRk2Aw4JUTL1$adKhB4NX2bJ3hn4jHLiNd40plkUr0Dmy3GaRzVacGa.";
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
      packages = with pkgs; [
        tree
        networkmanagerapplet
        pavucontrol
        # wayland
        glib # gsettings
        grim # screenshot functionality
        mako # notification system developed by swaywm maintainer
        slurp # screenshot functionality
        xwayland
        wayland
        waybar
        #wf-recorder
        wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
        wofi
      ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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

