{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.yggdrasil;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;

  keyDir = "/run/yggdrasil-key";
  pemPath = "${keyDir}/private.pem";
in
{
  options.hostModules.yggdrasil = {
    enable = mkEnableOption "Yggdrasil overlay mesh (infra-aberta hub peering)";

    peers = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tcp://163.176.224.45:1337" ];
      description = ''
        Yggdrasil Peers to dial. The default is the infra-aberta hub's reserved
        public IP (mesh/addresses.md in that repo). The local QEMU VM
        alternative is "tcp://10.0.2.2:1337" when working offline.
      '';
    };

    controlUsers = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "mbenevides" ];
      description = ''
        Users added to the `yggdrasil` group, which owns the admin socket, so
        `yggdrasilctl` (and the Noctalia plugin) work without root. This is
        full control of the node -- addPeer/removePeer included -- not a
        read-only view. Takes effect on the user's next login.
      '';
    };

    privateKeySecret = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "buzz_yggdrasil_pk";
      description = ''
        Name of the agenix secret (`<name>.age` in the nix-secrets input) holding
        this node's private key in the legacy hex `PrivateKey` format. It pins
        the node's address -- 200:33d9:7910:598a:baea:e295:2b4b:4d82 for the
        default key (mesh/addresses.md). Requires `hostModules.agenix`.

        Null runs without a key: yggdrasil then generates a throwaway identity,
        and therefore a new address, on every restart.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.yggdrasil = {
        enable = true;
        settings = {
          IfName = "ygg0";
          Peers = cfg.peers;
        };
      };

      # mesh/addresses.md keeps the hub in the operator's /etc/hosts, so the
      # admin target can be addressed as `guix-vm` (SSH is served on ygg0 only).
      networking.hosts."200:6e27:84a:50cc:1214:27d4:30f5:e659" = [ "guix-vm" ];
    }

    # The socket is created 0660 inside a 0750 runtime directory owned by
    # services.yggdrasil.group.
    (mkIf (cfg.controlUsers != [ ]) {
      users.groups.yggdrasil = { };
      services.yggdrasil.group = "yggdrasil";
      users.users = lib.genAttrs cfg.controlUsers (_: {
        extraGroups = [ "yggdrasil" ];
      });
    })

    (mkIf (cfg.privateKeySecret != null) {
      assertions = [
        {
          assertion = config.hostModules.agenix.enable;
          message = "hostModules.yggdrasil.privateKeySecret needs hostModules.agenix.enable = true.";
        }
      ];

      age.secrets.${cfg.privateKeySecret} = {
        file = "${inputs.nix-secrets}/${cfg.privateKeySecret}.age";
        owner = "root";
        mode = "0400";
      };

      # nixpkgs rejects settings.PrivateKey (it would land in the store) and
      # PrivateKeyPath expects PEM, while the secret holds the legacy hex key.
      # Convert it on every boot into a root-only tmpfs file; the key goes
      # through stdin, never argv.
      systemd.services.yggdrasil-key = {
        description = "Convert the agenix Yggdrasil key to PEM";
        before = [ "yggdrasil.service" ];
        requiredBy = [ "yggdrasil.service" ];
        path = [
          pkgs.jq
          config.services.yggdrasil.package
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = baseNameOf keyDir;
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
        };
        script = ''
          jq -Rn 'input | {PrivateKey: .}' < ${config.age.secrets.${cfg.privateKeySecret}.path} \
            | yggdrasil -useconf -exportkey > ${pemPath}
        '';
      };

      services.yggdrasil.settings.PrivateKeyPath = pemPath;
    })
  ]);
}
