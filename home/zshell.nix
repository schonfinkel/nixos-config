{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.zshell;
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
        nix-clean = "nix-collect-garbage -d --delete-old && sudo nix-collect-garbage -d --delete-old";
        hstat = "curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1";
        l = "ls -l";
        ls = "ls -h --group-directories-first --color=auto";
        la = "ls -lAh --group-directories-first --color=auto";
        psf = "pass find";
        psc = "pass --clip";
        poc = "pass otp --clip";
        r = "ranger";
        rsync = "rsync -chavzP --stats";
        vi = "nvim";
        vim = "nvim";
        sshk = "kitty +kitten ssh";
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
