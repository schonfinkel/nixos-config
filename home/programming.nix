{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.programming;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.programming = {
    enable = mkEnableOption "Enable a minimal programming environment.";

    git = {
      enable = mkEnableOption "Enable Git configuration" // {
        default = true;
      };

      defaultEditor = mkOption {
        type = lib.types.str;
        default = "nvim";
        description = "Default editor for Git";
      };

      defaultUser = lib.mkOption {
        type = lib.types.attrs;
        default = {
          main = {
            email = "marcos.schonfinkel@gmail.com";
            name = "Marcos Benevides";
            signingKey = "5E35E6094143FA7A";
          };
        };
        description = "Default User for Git";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        azure-cli
        kubectl
        lens

        # Editors
        jetbrains.rider

        # For Git
        bfg-repo-cleaner
        git-crypt
        gitflow
        git-lfs
        git-subrepo
        meld

        # Language Servers
        lua-language-server
        nil
        # Tools
        hoppscotch
        gnumake
        shellcheck
      ];

      manual.manpages.enable = true;

      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv = {
          enable = true;
        };
      };
    }

    # Git configuration
    (mkIf cfg.git.enable {
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.git = {
        enable = true;

        ignores = [
          # nix
          "result"

          # direnv/devenv
          ".devenv"
          ".direnv"
          ".pre-commit-config.yaml"
        ];

        settings = {
          alias = {
            # Aliases
            commit = "commit -S";
            a = "add";
            ap = "add -p";
            c = "clone";
            ca = "commit --amend";
            can = "commit --amend --no-edit";
            cam = "commit --amend -m";
            cm = "commit -m";
            ds = "diff --staged";
            dc = "diff --name-only --diff-filter=U";
            fixup = "!git log --oneline --decorate @{u}.. | fzy | awk '{ print $1 }' | xargs -I{} git commit --fixup={}";
            fo = "fetch origin";
            lo = "log --oneline";
            ls = "log -S";
            po = "push origin";
            pof = "push -f origin";
            pro = "pull --rebase origin";
            ra = "rebase --abort";
            rc = "rebase --continue";
            ri = "rebase -i";
            # Pretty
            branches = "branch --sort=-committerdate --format='%(HEAD)%(color:yellow) %(refname:short) | %(color:bold red)%(committername) | %(color:bold green)%(committerdate:relative) | %(color:blue)%(subject)%(color:reset)' --color=always";
            tree = "log --graph --oneline --decorate --all";
          };

          core = {
            editor = cfg.git.defaultEditor;
            commentChar = ";";
          };

          init = {
            defaultBranch = "main";
          };

          merge = {
            tool = "meld";
          };

          lfs = {
            enable = true;
          };

          push = {
            autoSetupRemote = true;
          };

          safe = {
            directory = "~/Code/NixOS";
          };

          user = {
            email = cfg.git.defaultUser.main.email;
            name = cfg.git.defaultUser.main.name;
          };

        };

        includes = [
          {
            condition = "gitdir:~/Code/";
            contents = {
              user = cfg.git.defaultUser.main;
              commit = {
                gpgSign = true;
              };
            };
          }

          {
            condition = "gitdir:~/.password-store/";
            contents = {
              user = cfg.git.defaultUser.main;
              commit = {
                gpgSign = true;
              };
            };
          }
        ];
      };

      # Needed for some work stuff
      programs.gh = {
        enable = true;
        settings = {
          editor = cfg.git.defaultEditor;
        };
      };

    })
  ]);
}
