{
  config,
  lib,
  ...
}:

let
  cfg = config.hostModules.yggdrasil;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    ;
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
  };

  config = mkIf cfg.enable {
    services.yggdrasil = {
      enable = true;
      # No PrivateKey here on purpose (secrets deferred): without one,
      # yggdrasil generates a throwaway identity -- and therefore a NEW
      # address -- on every restart. The committed laptop address
      # 200:33d9:7910:598a:baea:e295:2b4b:4d82 (mesh/addresses.md) requires
      # the keypair; inject it later as settings.PrivateKey via agenix.
      settings = {
        IfName = "ygg0";
        Peers = cfg.peers;
      };
    };

    # mesh/addresses.md keeps the hub in the operator's /etc/hosts, so the
    # admin target can be addressed as `guix-vm` (SSH is served on ygg0 only).
    networking.hosts."200:6e27:84a:50cc:1214:27d4:30f5:e659" = [ "guix-vm" ];
  };
}
