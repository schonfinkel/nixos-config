# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Custom Modules
    ../../modules

    # Virtualisation
    ../../virtualisation/docker.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_6_12;

  # https://github.com/nix-community/nixos-generators?tab=readme-ov-file#cross-compiling
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Allow unfree packages
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
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
    };
  };

  # Hardware
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # GPU Config
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  hardware.nvidia = {
    # Use the NVidia open source kernel module
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Some extra hyprland + nvidia crap
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
  };

  # Enable the GNOME Desktop Environment.
  #services.xserver.displayManager.gdm.enable = true;
  #services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.schonfinkel = {
    isNormalUser = true;
    description = "schonfinkel";
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
  };

  programs.noisetorch.enable = true;

  # Enable Host modules
  hostModules.audio = {
    enable = true;
  };

  hostModules.commons = {
    enable = true;
    hostName = "caladan";
  };

  hostModules.hyprland = {
    enable = true;
  };

  hostModules.impermanence = {
    enable = true;
    username = "schonfinkel";
  };

  hostModules.ssh = {
    enable = true;
    allowUsers = [ "schonfinkel" ];
  };

  hostModules.themes = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
