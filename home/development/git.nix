{pkgs, ...}:

let
  main = {
    email = "marcos.schonfinkel@gmail.com";
    name = "Marcos Benevides";
    signingKey = "5E35E6094143FA7A";
  };
in
{
  home.packages = with pkgs; [
    bfg-repo-cleaner
    gitAndTools.gitflow
    gitAndTools.git-subrepo
    git-crypt
    meld
  ];

  # Needed for some work stuff
  programs.gh = {
    enable = true;
    settings = {
      editor = "nvim";
    };
  };

  programs.git = {
    enable = true;

    userEmail = main.email;
    userName = main.name;

    ignores = [
      # nix
      "result"

      # direnv/devenv
      ".envrc"
      ".direnv"
      ".devenv"
      ".pre-commit-config.yaml"

      # vscode
      ".vscode"
    ];

    aliases = {
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
    };

    delta = {
      enable = true;
    };

    lfs = {
      enable = true;
    };

    extraConfig = {
      core = {
        editor = "nvim";
        commentChar = ";";
      };

      push.autoSetupRemote = true;

      init = {
        defaultBranch = "main";
      };

      safe = {
        directory = "~/Code/NixOS";
      };

      merge = {
        tool = "meld";
      };
    };

    includes = [
      {
        condition = "gitdir:~/Code/";
        contents = {
          user = main;
          commit = {
            gpgSign = true;
          };
        };
      }

      {
        condition = "gitdir:~/Work/";
        path = "~/Work/.gitconfig";
      }

      {
        condition = "gitdir:~/Personal/";
        path = "~/Personal/.gitconfig";
      }

      {
        condition = "gitdir:~/.password-store/";
        contents = {
          user = main;
          commit = {
            gpgSign = true;
          };
        };
      }
    ];
  };
}
