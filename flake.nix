{
  description = "NixOS Configuration";

  # Prebuilt Noctalia binaries come from its Cachix cache. Kept at flake level
  # so anyone building this flake (not just the deployed hosts) can fetch them
  # instead of compiling Noctalia from source.
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

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

    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    noctalia.url = "github:noctalia-dev/noctalia/cachix";

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
          system = "x86_64-linux";

          # Port Fowarding (HOST -> VM)
          # - SSH: 2222 -> 22
          qemu_options = {
            net = "hostfwd=tcp:127.0.0.1:2222-:22";
          };

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
            qemu = self.nixosConfigurations.peano.config.system.build.images.qemu-repart;
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
                ${pkgs.nix}/bin/nix build ".#nixosConfigurations.peano.config.system.build.vmWithDisko" "$@"

                export QEMU_KERNEL_PARAMS="console=ttyS0"
                export QEMU_NET_OPTS=${qemu_options.net}

                echo "Running VM..."
                ${pkgs.nix}/bin/nix run -L ".#nixosConfigurations.peano.config.system.build.vmWithDisko"
              ''}";
            };
          };

          # nix develop
          devShells = {
            # `nix develop .#ci`
            # reduce the number of packages to the bare minimum needed for CI
            ci = pkgs.mkShell {
              buildInputs = with pkgs; [
                age
                just
                nixos-rebuild
              ];
            };

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

          settings = import ./profiles/settings.nix;

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
                  home-manager.extraSpecialArgs = { inherit inputs; };
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
              # Thinkpad
              euclid =
                let
                  particular = [
                    nixos-hardware.nixosModules.lenovo-thinkpad-l13
                  ];
                in
                mkHost "euclid" "mbenevides" (extra ++ particular);

              # Quick-install host for new machines. Everything except agenix:
              # stylix is not optional here, since home/hyprland.nix is built on
              # its colour scheme.
              tarski = mkHost "tarski" "mbenevides" [
                disko.nixosModules.disko
                impermanence.nixosModules.impermanence
                stylix.nixosModules.stylix
              ];

              # Disks are declared in profiles/disko/ext4_ephemeral.nix and wired up
              # through hostModules.disko, so no extra specialArgs are needed
              # here -- modules/disko.nix reads profiles/settings.nix itself.
              schonfinkel =
                let
                  particular = [
                    disko.nixosModules.disko
                  ];
                in
                mkHost "schonfinkel" "mbenevides" (extra ++ particular);

              peano = lib.nixosSystem {
                inherit system;
                modules = [
                  agenix.nixosModules.default
                  disko.nixosModules.disko
                  impermanence.nixosModules.impermanence
                  stylix.nixosModules.stylix
                  ./hosts/peano/configuration.nix
                  ({ nixpkgs, ... }: {
                    nixpkgs.overlays = [
                      (final: prev: {
                        aggregateModules =
                          modules:
                          let
                            result = prev.aggregateModules modules;
                          in
                          result
                          // {
                            target = (builtins.head modules).target or "bzImage";
                          };
                      })
                    ];
                  })
                ];
                specialArgs = {
                  inherit inputs system;
                  hostId = "3244f94e";
                  profile = "ext4";
                  target = settings.peano;
                };
              };
            };
        };
    };

}
