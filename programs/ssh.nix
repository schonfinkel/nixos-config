{
  config,
  modulesPath,
  lib,
  options,
  pkgs,
}:

{
  programs.ssh.agentTimeout = "1h";
  programs.ssh.startAgent = true;
}
