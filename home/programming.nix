{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Work git identities: repo directory -> agenix secret (nix-secrets input)
  # holding the `[user] email = ...` fragment, so the addresses stay out of this
  # public repo. modules/agenix.nix decrypts them to /run/agenix for any user
  # with enableWorkProfile on.
  workIdentities = {
    "~/Code/Work/opslogic/" = "mail_ol";
    "~/Code/Work/foratravel/" = "mail_fat";
  };

  # https://github.com/NixOS/nixpkgs/issues/563241#issuecomment-5728169843
  # opencode_patch = pkgs.opencode.overrideAttrs (
  #   final: prev: {
  #     postPatch = prev.postPatch + ''
  #       # fix for bun 1.4.x
  #       substituteInPlace packages/opencode/script/build.ts \
  #         --replace-fail 'splitting: true,' 'splitting: false,'
  #     '';
  #   }
  # );

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

    enableWorkProfile =
      mkEnableOption "Enable a separate 'work' profile for companies that require a dedicated work account"
      // {
        default = false;
      };

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
        # AI
        # opencode_patch
        opencode
        claude-code
        codex
        cursor-cli

        # azure-cli
        # azure-functions-core-tools
        kubectl
        kubectx

        # Diagrams
        d2

        # Editors
        # jetbrains.rider

        # For Git
        bfg-repo-cleaner
        git-crypt
        gitflow
        git-lfs
        git-secrets
        git-subrepo
        meld

        # Language Servers
        lua-language-server
        nixd

        # Tools
        devenv
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

        lfs = {
          enable = true;
        };

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
          # Personal Projects
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

    (mkIf cfg.enableWorkProfile {
      home.packages = with pkgs; [
        # Cloud
        awscli2
        saml2aws

        # K8s
        lens

        # Tools
        jira-cli-go
      ];

      # Declaratively write the public "work" key file
      # Run `gpg --export-ssh-key B653691B6E9D5D4A` once to get this string
      home.file.".ssh/work_github.pub".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITVJEmPZNwWxuZ/eiqapSzIGUD42KknahJwzhaCJpRL (none)
      '';

      # Declaratively configure SSH Host alias and force IdentitiesOnly
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "github.com-work" = {
            hostname = "github.com";
            user = "git";
            identitiesOnly = true;
            identityFile = "~/.ssh/work_github.pub";
          };
        };
      };

      # Add extra git options. Each work identity is two includes with the same
      # condition: the non-secret settings, then the decrypted email fragment.
      programs.git = {
        includes = lib.concatLists (
          lib.mapAttrsToList (dir: secret: [
            {
              condition = "gitdir:${dir}";
              contents = {
                user = {
                  name = "Marcos Benevides";
                  signingKey = "B653691B6E9D5D4A";
                };
                commit.gpgSign = true;
                url."git@github.com-work:".insteadOf = "git@github.com:";
              };
            }
            {
              condition = "gitdir:${dir}";
              path = "/run/agenix/${secret}";
            }
          ]) workIdentities
        );
      };

    })
  ]);
}
