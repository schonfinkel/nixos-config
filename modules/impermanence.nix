{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.impermanence;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.hostModules.impermanence = {
    enable = mkEnableOption "Enable/Disable the 'impermanence' module";

    persistDirectory = mkOption {
      type = lib.types.str;
      default = "/nix/persist";
    };

    username = mkOption {
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.persistence."${cfg.persistDirectory}" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/etc/ssh"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/log"
          # Age keys for servers, etc
          "/var/secrets"
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
        users."${cfg.username}" = {
          directories = [
            ".aws"
            ".config/BraveSoftware"
            ".config/discord"
            ".config/gh"
            ".config/ngrok"
            ".config/Signal"
            ".config/Slack"
            # Age keys for local development
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

    })
  ]);
}
