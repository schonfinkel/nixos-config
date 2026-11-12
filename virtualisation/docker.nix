{
  config,
  lib,
  modulesPath,
  pkgs,
  options,
  specialArgs,
  ...
}:

{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      dates = "weekly";
      enable = true;
      flags = [ "--all" ];
    };
  };

  environment.systemPackages = (
    with pkgs;
    [
      docker-compose
    ]
  );

  # fakecloud needs this to emulate some services
  networking.firewall.trustedInterfaces = [ "docker0" ];
}
