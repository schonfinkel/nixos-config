# https://github.com/nix-community/impermanence#module-usage
{
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"
      "/var/secrets"
      # Age keys for servers, etc
    ];
    files = [
      # machine-id is used by systemd for the journal, if you don't persist this
      # file you won't be able to easily use journalctl to look at journals for
      # previous boots.
      "/etc/machine-id"
      {
        file = "/var/hashed_user_pswd";
        parentDirectory = {
          mode = "u=rwx,g=,o=";
        };
      }
    ];
    users.mbenevides = {
      directories = [
        ".aws"
        ".config/BraveSoftware"
        ".config/discord"
        ".config/gh"
        ".config/glab-cli"
        ".config/mgc"
        ".config/Signal"
        ".config/Slack"
        # Age keys for local development
        ".config/sops/age"
        ".local/share/sddm"
        ".local/share/direnv"
        ".local/share/TelegramDesktop"
        ".nuget"
        "Code"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        {
          directory = ".password-store";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
      files = [
        ".bash_history"
        ".config/systemsettingsrc"
        ".pgpass"
        ".zsh_history"
      ];
    };
  };
}
