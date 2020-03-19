{pkgs, home, ...}:

let
  dotfiles = ../../../dotfiles;
in
{
  manual.manpages.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    nix.useSandbox = true;
  };

  nixpkgs.overlays = [
    (import ../../../overlays/conky.nix)
    (import ../../../overlays/ncmpcpp.nix)
    (import ../../../overlays/nvim/neovim.nix)
  ];

  home.packages = with pkgs; [
    arandr
    dict
    scrot
    tomb
    tmate
    shellcheck
    xclip
    # Browser
    brave
    # Daemons
    # ipfs
    earlyoom
    # Development
    awscli
    aws-vault
    vault
    #dbeaver
    dotnet-sdk
    gitlab-runner
    google-cloud-sdk
    heroku
    insomnia
    #postman
    siege
    travis
    vscodium
    # Chat
    weechat
    tdesktop
    #zoom-us
    # Graphics/Design
    gimp
    krita
    # i3-related
    dmenu
    i3lock-fancy
    # Media
    feh
    mpv
    ncmpcpp
    # Torrents
    transmission-gtk
    # Gaming
    discord
    #lutris
    #retroarch
    steam
    # Utils
    obs-studio
    youtube-dl
    ranger
    # Rice
    conky
    neofetch
    pywal
    # Tools
    alacritty
    #hadolint
    shellcheck
    # Remove later
    ffmpegthumbnailer
    djvulibre
    poppler_utils
    # Other
	waifu2x-converter-cpp
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.firefox = {
    enable = true;
  };

  programs.chromium = {
    enable = true;
  };

  programs.newsboat = {
    enable = false;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    #defaultKeymap = "vicmd";
    shellAliases = {
      icat="kitty +kitten icat";
      hstat="curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1";
      ls="ls -h --group-directories-first --color=auto";
      la="ls -lAh --group-directories-first --color=auto";
      r="ranger";
      svim="sudo vim";
      xcc="xclip -sel clipboard";
    };
    history = {
      size = 5000;
      ignoreDups = true;
    };
    initExtra = builtins.readFile "${dotfiles}/zsh/zshrc";
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      directory = {
        prefix = "";
      };
      prompt_order = [
        "username"
        "hostname"
        "directory"
        # Git
        "git_branch"
        "git_commit"
        "git_state"
        # Langs/Tools
        "dotnet"
        "haskell"
        "nix_shell"
        "nodejs"
        "python"
        "rust"
        "terraform"
        "line_break"
        "character"
      ];
      # Git
      git_commit = {
        disabled = false;
      };
      # Hostname
      hostname = {
        ssh_only = false;
        prefix = "⟪";
        suffix = "⟫";
      };
      # Username
      username.show_always = true;
    };
  };

  programs.zathura = {
    enable = true;
  };

  services.dunst = {
    enable = true;
  };

  services.mpd = {
    enable = true;
    dataDir = builtins.toPath "/home/usul/.mpd";
    musicDirectory = builtins.toPath "/home/usul/Music";
    network = {
      listenAddress = "127.0.0.1";
      port = 6600;
    };
    extraConfig = ''
      audio_output {
        type      "pulse"
        name      "Local Music Player Daemon"
      }

      audio_output {
        type      "fifo"
        name      "my_fifo"
        path      "/tmp/mpd.fifo"
        format    "44100:16:2"
      }
    '';
  };

  services.polybar = {
    enable = true;
    extraConfig = builtins.readFile "${dotfiles}/polybar/config";
    package = pkgs.polybarFull;
    script = builtins.readFile "${dotfiles}/polybar/launch.sh";
  };

  # Dotfiles
  home.file.".ncmpcpp/config".source = builtins.toString "${dotfiles}/ncmpcpp/config}";

  home.sessionVariables = {
    EDITOR = "vim";
    # Spaceship related
    SPACESHIP_EXIT_CODE_SHOW = "true";
  };

  xdg.configFile = {
    "kitty/kitty.conf".source = builtins.toString "${dotfiles}/kitty/kitty.conf";
    "i3/config".text = import "${dotfiles}/i3wm/config.nix" {};
    "ranger" = {
      source = builtins.toString "${dotfiles}/ranger";
      recursive = true;
    };
  };
}
