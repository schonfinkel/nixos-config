{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Directories
    ../../home
  ];

  home = {
    username = "mbenevides";
    homeDirectory = "/home/mbenevides";
  };

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
    # TODO: adjust once the real outputs are known (`hyprctl monitors`).
    monitors = [
      "HDMI-A-1,highres,0x0,2"
    ];
  };

  # AI coding agents (llm-agents.nix) + declarative MCP servers.
  homeModules.llms = {
    enable = true;

    # Work MCPs: loaded by codex/cursor/opencode and by `cc` under the work
    # profile. Jenkins URL/token come from /run/agenix at runtime.
    mcpServers = {
      datadog = {
        # OAuth: authenticate once per client (`/mcp`, `codex mcp login`, ...).
        url = "https://mcp.datadoghq.com/v1/mcp?toolsets=core";
      };
      "jenkins-mcp" = {
        urlSecret = "jenkins_staging_url";
        secretHeaders.Authorization = {
          secret = "jenkins_staging_token";
          prefix = "Basic ";
        };
      };
    };

    # Secret-free servers available on every profile and host.
    personalMcpServers = {
      nixos.command = "${inputs.mcp-nixos.packages.${pkgs.system}.mcp-nixos}/bin/mcp-nixos";
    };
  };

  homeModules.noctalia = {
    enable = true;
  };

  homeModules.ghostty = {
    enable = true;
  };

  homeModules.media = {
    enable = true;
  };

  homeModules.neovim = {
    enable = true;
  };

  homeModules.programming = {
    enable = true;
    enableWorkProfile = true;
  };

  homeModules.security = {
    enable = true;
    gpg = {
      enable = true;
      sshKeys = [
        "23C94318A1D57DA26574677539EC504CB2A49981"
        "66B671191FC245EC5A814702D4EFEF49D4E53C9E"
      ];
    };
  };

  homeModules.themes = {
    enable = true;
  };

  # homeModules.vscode = {
  #   enable = true;
  # };

  homeModules.zshell = {
    enable = true;
  };
}
