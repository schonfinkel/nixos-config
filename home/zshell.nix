{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.zshell;

  # Datadog's hosted MCP server, loaded only by the work profile (`ccw`).
  # Auth is OAuth (run `/mcp` once inside `ccw`), so no secret lives here.
  datadogMcp = (pkgs.formats.json { }).generate "datadog-mcp.json" {
    mcpServers.datadog = {
      type = "http";
      url = "https://mcp.datadoghq.com/v1/mcp?toolsets=core";
    };
  };
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.zshell = {
    enable = mkEnableOption "Enable a custom VS Code setup";

    histSize = mkOption {
      type = lib.types.int;
      default = 7000;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    ];

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      shellAliases = {
        ccp = "CLAUDE_CONFIG_DIR=$HOME/.claude/personal claude";
        ccw = "CLAUDE_CONFIG_DIR=$HOME/.claude/work claude --mcp-config ${datadogMcp}";
        nix-clean = "nix-collect-garbage -d --delete-old && sudo nix-collect-garbage -d --delete-old";
        hstat = "curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1";
        l = "ls -l";
        ls = "ls -h --group-directories-first --color=auto";
        la = "ls -lAh --group-directories-first --color=auto";
        psf = "pass find";
        psc = "pass --clip";
        poc = "pass otp --clip";
        repair-store = "nix-store --verify --check-contents --repair";
        rsync = "rsync -chavzP --stats";
        vi = "nvim";
        vim = "nvim";
        y = "yazi";
        ytdl = "nix run nixpkgs#yt-dlp --";
      };
      history = {
        size = cfg.histSize;
      };
      initContent = builtins.readFile ../dotfiles/zsh/zshrc;
    };

    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        directory = {
          truncation_length = 2;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };
        # Git
        git_commit = {
          disabled = false;
        };
        # Hostname
        hostname = {
          ssh_only = false;
          format = "⟪[$hostname]($style)⟫ ";
        };
        username.show_always = true;
      };
    };

    home.sessionVariables = {
      SPACESHIP_EXIT_CODE_SHOW = "true";
    };
  };
}
