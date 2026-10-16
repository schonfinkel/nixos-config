{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  home = {
    username = "mbenevides";
    homeDirectory = "/home/mbenevides";
  };

  imports = [
    # Directories
    ../../home
  ];

  programs = {
    home-manager.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Custom Home modules
  homeModules.commons = {
    enable = true;
  };

  homeModules.chats = {
    enable = true;
  };

  homeModules.emacs = {
    enable = true;
  };

  homeModules.hyprland = {
    enable = true;
    monitors = [
      "HDMI-A-1,highres,0x0,2"
      "eDP-1,highres,1920x0,1"
    ];
    # Keyboard layout is inherited from services.xserver.xkb in ./configuration.nix.
  };

  homeModules.noctalia = {
    enable = true;
  };

  homeModules.ghostty = {
    enable = true;
  };

  # AI coding agents (llm-agents.nix) + declarative MCP servers. Work MCPs
  # (datadog/jenkins) stay off this machine; the nixos option-search server
  # is secret-free and useful everywhere.
  homeModules.llms = {
    enable = true;
    personalMcpServers = {
      nixos.command = "${
        inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos
      }/bin/mcp-nixos";
    };
  };

  homeModules.media = {
    enable = true;
  };

  homeModules.neovim = {
    enable = true;
  };

  homeModules.programming = {
    enable = true;
  };

  homeModules.security = {
    enable = true;
    gpg = {
      enable = true;
      sshKeys = [
        "23C94318A1D57DA26574677539EC504CB2A49981"
      ];
    };
  };

  homeModules.themes = {
    enable = true;
  };

  homeModules.zshell = {
    enable = true;
  };

  homeModules.vscode = {
    enable = true;
  };
}
