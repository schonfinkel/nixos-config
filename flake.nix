{ 
  description = "NixOS Configuration";

  inputs = {
    emacs = {
      url = "github:nix-community/emacs-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    hyprland.url = "github:hyprwm/Hyprland";

    stylix.url = "github:danth/stylix";

    hosts.url = "github:StevenBlack/hosts";
  };

  outputs = { self, impermanence, home, hosts, stylix, nixpkgs, ... }@inputs:
  let
    lib = nixpkgs.lib;

    system = "x86_64-linux";
  in
  {
    nixosConfigurations = {
      caladan = lib.nixosSystem {
        inherit system;

        modules = [
          ./documentation.nix
          ./fonts.nix
          ./hosts/caladan/configuration.nix
          ./overlays
          stylix.nixosModules.stylix
          hosts.nixosModule {
            networking.stevenBlackHosts = {
              enable = true;
              blockPorn = true;
            };
          }
          home.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bkp";
            home-manager.users.leto = import ./hosts/caladan/users.nix;
          }
        ];

        specialArgs = { inherit inputs system; };
      };

      euclid = lib.nixosSystem {
        inherit system;

        specialArgs = { inherit inputs system; };

        modules = [
          impermanence.nixosModules.impermanence
          stylix.nixosModules.stylix
          hosts.nixosModule {
            networking.stevenBlackHosts = {
              enable = true;
              blockPorn = true;
            };
          }
          home.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mbenevides = import ./hosts/euclid/home.nix;
          }
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l13
          ./documentation.nix
          ./fonts.nix
          ./hosts/euclid/configuration.nix
        ];
      };
    };
  };
}
