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
    ];
    files = [
      # machine-id is used by systemd for the journal, if you don't persist this
      # file you won't be able to easily use journalctl to look at journals for
      # previous boots.
      "/etc/machine-id"
    ];
    users.mbenevides = {
      directories = [
        ".aws"
        ".config/BraveSoftware"
        ".config/discord"
        ".config/gh"
        ".config/mgc"
        ".config/Signal"
        ".config/Slack"
        ".local/share/sddm"
        ".local/share/direnv"
        ".local/share/TelegramDesktop"
        ".local/state/nvim/dbee"
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
