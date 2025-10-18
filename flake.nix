{
  description = "NixOS Configuration";

  inputs = {
    agenix.url = "github:ryantm/agenix";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs = {
      url = "github:nix-community/emacs-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hosts.url = "github:StevenBlack/hosts";

    hyprland.url = "github:hyprwm/Hyprland";

    impermanence.url = "github:nix-community/impermanence";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    stylix.url = "github:danth/stylix";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      agenix,
      devenv,
      flake-parts,
      impermanence,
      home,
      hosts,
      hyprland,
      nixpkgs,
      nixos-hardware,
      stylix,
      treefmt-nix,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, system, ... }:
        let
          lib = nixpkgs.lib;

          system = "x86_64-linux";

          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          # This sets `pkgs` to a nixpkgs with allowUnfree option set.
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # nix run
          apps = {
          };

          # nix develop
          devShells = {
          };

          # nix fmt
          formatter = treefmtEval.config.build.wrapper;
        };

      flake =
        let
          lib = nixpkgs.lib;

          system = "x86_64-linux";

          mkHost =
            host: extraModules:
            lib.nixosSystem {
              inherit system;

              modules = [
                ./documentation.nix
                ./fonts.nix
                ./hosts/${host}/configuration.nix
                ./overlays
                hosts.nixosModule
                {
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
                  home-manager.users.leto = import ./hosts/${host}/home.nix;
                }
              ]
              ++ extraModules;

              specialArgs = { inherit inputs system; };
            };
        in
        {

          nixosConfigurations = {
            caladan = mkHost "caladan" [ ];

            euclid =
              let
                extraModules = [
                  agenix.nixosModules.default
                  impermanence.nixosModules.impermanence
                  stylix.nixosModules.stylix
                  nixos-hardware.nixosModules.lenovo-thinkpad-l13
                ];
              in
              mkHost "euclid" extraModules;

          };

        };
    };

}
