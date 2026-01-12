{
  description = "NixOS Configuration";

  inputs = {
    agenix.url = "github:ryantm/agenix";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
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

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      agenix,
      devenv,
      disko,
      flake-parts,
      impermanence,
      home,
      hosts,
      hyprland,
      nixpkgs,
      nixos-generators,
      nixos-hardware,
      nix-vscode-extensions,
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

          # Port Fowarding (HOST -> VM)
          # - SSH: 2222 -> 22
          qemu_options = {
            net = "hostfwd=tcp:127.0.0.1:2222-:22";
          };

          settings = import ./profiles/settings.nix;

          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          # This sets `pkgs` to a nixpkgs with allowUnfree option set.
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # nix build
          packages = {
            # QEMU
            # nix build .#qemu
            qemu = nixos-generators.nixosGenerate {
              system = "x86_64-linux";
              modules = [
                agenix.nixosModules.default
                disko.nixosModules.disko
                impermanence.nixosModules.impermanence
                ./hosts/peano/configuration.nix
                (import ./overlays)
              ];
              specialArgs = {
                hostId = "3244f94e";
                profile = "ext4";
                target = settings.peano;
              };
              format = "qcow";
            };
          };

          # nix run
          apps = {
            # https://github.com/nix-community/disko/blob/a5c4f2ab72e3d1ab43e3e65aa421c6f2bd2e12a1/docs/disko-images.md#test-the-image-inside-a-vm
            # nix run .#qemu
            qemu = {
              type = "app";

              program = "${pkgs.writeShellScript "run-vm.sh" ''
                set -e
                echo "Building VM with Disko..."
                ${pkgs.nix}/bin/nix build ".#nixosConfigurations.bootstrap_vm.config.system.build.vmWithDisko" "$@"

                export QEMU_KERNEL_PARAMS="console=ttyS0"
                export QEMU_NET_OPTS=${qemu_options.net}

                echo "Running VM..."
                ${pkgs.nix}/bin/nix run -L ".#nixosConfigurations.bootstrap_vm.config.system.build.vmWithDisko"
              ''}";
            };
          };

          # nix develop
          devShells = {
            # nix develop --impure
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                (
                  { pkgs, lib, ... }:
                  {
                    packages = with pkgs; [
                      age
                      agenix.packages.${system}.default
                      just
                    ];

                    enterShell = ''
                      Entering dev shell
                    '';
                  }
                )
              ];
            };
          };

          # nix fmt
          formatter = treefmtEval.config.build.wrapper;
        };

      flake =
        let
          lib = nixpkgs.lib;

          system = "x86_64-linux";

          mkHost =
            host: user: extraModules:
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
                  home-manager.users."${user}" = import ./hosts/${host}/home.nix;
                }
              ]
              ++ extraModules;

              specialArgs = { inherit inputs system; };
            };
        in
        {
          nixosConfigurations = 
            let
              extra = [
                agenix.nixosModules.default
                impermanence.nixosModules.impermanence
                stylix.nixosModules.stylix
              ];
            in
            {
              # Caladan will be deprecated soon
              caladan = 
                mkHost "caladan" "leto" extra;
              euclid =
                let
                  particular = [ 
                    nixos-hardware.nixosModules.lenovo-thinkpad-l13
                  ];
                in
                  mkHost "euclid" "mbenevides" (extra ++ particular);
            };
        };
    };

}
