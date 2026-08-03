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

  # Home-relative directories persisted for cfg.username. Entries are either a
  # plain string or an attrset carrying a mode.
  userDirectories = [
    ".android"
    ".aws"
    ".azure"
    ".config/BraveSoftware"
    ".config/discord"
    ".config/gh"
    ".config/mgc"
    ".config/opencode"
    ".config/Signal"
    ".config/Slack"
    ".claude"
    ".kube"
    ".local/share/opencode"
    ".local/share/sddm"
    ".local/share/direnv"
    ".local/share/TelegramDesktop"
    ".local/state/nvim/dbee"
    ".local/state/opencode"
    ".microsoft/usersecrets"
    ".nuget"
    ".oci"
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

  directoryName = d: if lib.isString d then d else d.directory;

  # Anything handed to the data disk is dropped here, so a directory is never
  # claimed by two persistence roots at once.
  mainUserDirectories = builtins.filter (
    d: !(builtins.elem (directoryName d) cfg.dataUserDirectories)
  ) userDirectories;
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
      default = "mbenevides";
    };

    dataDirectory = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional second persistence root, for hosts that keep bulk user data on
        a separate disk. Nothing extra is declared while this is null.
      '';
      example = "/persist/data";
    };

    dataUserDirectories = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Home-relative directories to persist under `dataDirectory` rather than
        `persistDirectory`. Names listed here are removed from the default set.
      '';
      example = [
        "Music"
        "Videos"
      ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.persistence."${cfg.persistDirectory}" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          # This is the directory where we'll dump a private key
          # that will need to be used for "stage 2", when agenix
          # is enabled and requires a key to unlock the secrets.
          "/var/lib/agenix"
          "/var/lib/docker/"
          "/var/lib/nixos"
          "/var/lib/postgresql"
          "/var/lib/tailscale"
          "/var/lib/systemd/coredump"
          "/var/log"
        ];
        files = [
          # machine-id is used by systemd for the journal, if you don't persist this
          # file you won't be able to easily use journalctl to look at journals for
          # previous boots.
          "/etc/machine-id"
        ];
        users."${cfg.username}" = {
          directories = mainUserDirectories;
          files = [
            ".bash_history"
            ".config/systemsettingsrc"
            ".pgpass"
            ".zsh_history"
          ];
        };
      };

    }

    # Bulk user data living on a separate (usually slower) disk.
    (mkIf (cfg.dataDirectory != null) {
      environment.persistence."${cfg.dataDirectory}" = {
        hideMounts = true;
        users."${cfg.username}" = {
          directories = cfg.dataUserDirectories;
        };
      };
    })
  ]);
}
