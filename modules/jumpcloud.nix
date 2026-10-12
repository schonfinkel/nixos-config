{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.jumpcloud;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    ;

  secretName = profile: "jumpcloud_${profile}_ovpn";

  # `jumpcloud-vpn <profile> [up|down|toggle|status]`. Passing the .ovpn path
  # straight to openvpn3 imports it as a throwaway config named after that path,
  # so nothing has to survive the tmpfs root and `down` can address it the same
  # way. Progress also goes to notify-send, since the Noctalia bar buttons
  # (home/noctalia.nix) have no terminal.
  jumpcloudVpn = pkgs.writeShellApplication {
    name = "jumpcloud-vpn";
    runtimeInputs = [
      config.programs.openvpn3.package
      pkgs.gawk
      pkgs.libnotify
    ];
    text = ''
      usage() {
        echo "usage: jumpcloud-vpn <${lib.concatStringsSep "|" cfg.profiles}> [up|down|toggle|status]" >&2
        exit 1
      }

      [ $# -ge 1 ] || usage
      profile=$1
      case "$profile" in
      ${lib.concatMapStrings (profile: ''
        ${profile}) ovpn=${config.age.secrets.${secretName profile}.path} ;;
      '') cfg.profiles}
        *) usage ;;
      esac

      notify() { notify-send --app-name=JumpCloud --icon=network-vpn "JumpCloud $profile" "$1" || true; }

      # Status line of this profile's session, empty when there is none.
      session_status() {
        openvpn3 sessions-list 2>/dev/null | awk -v cfg="$ovpn" '
          /^-+$/ { mine = 0 }
          /Config name:/ { mine = index($0, cfg) > 0 }
          mine && /Status:/ { sub(/.*Status: */, ""); print; exit }
        '
      }

      up() {
        if [ -n "$(session_status)" ]; then
          notify "Already running: $(session_status)"
          return
        fi
        # The server answers with a JumpCloud SAML URL that openvpn3 opens in
        # the browser; the tunnel comes up once that login (and MFA) succeeds.
        notify "Connecting, finish the login in your browser"
        openvpn3 session-start --config "$ovpn"
        for _ in $(seq 180); do
          case "$(session_status)" in
            *"Client connected"*) notify "Connected"; return ;;
            "") notify "Connection failed"; exit 1 ;;
          esac
          sleep 1
        done
        notify "Still not connected after 3 minutes: $(session_status)"
        exit 1
      }

      down() {
        openvpn3 session-manage --config "$ovpn" --disconnect
        notify "Disconnected"
      }

      case "''${2:-up}" in
        up) up ;;
        down) down ;;
        toggle) if [ -n "$(session_status)" ]; then down; else up; fi ;;
        status) echo "''${profile}: $(session_status || true)" ;;
        *) usage ;;
      esac
    '';
  };

  idpSecretName = env: "fora_idp_account_${env}";

  # `jumpcloud-aws [--stag|--prod]`: saml2aws login through JumpCloud, with the
  # username, password and TOTP read from 1Password. The saml2aws idp-account
  # names come from agenix secrets.
  jumpcloudAws = pkgs.writeShellApplication {
    name = "jumpcloud-aws";
    runtimeInputs = [ pkgs.saml2aws ];
    text = ''
      # The desktop app only talks to the setgid (onepassword-cli) wrapper that
      # programs._1password installs, not to the bare store binary.
      op() { ${config.security.wrapperDir}/op "$@"; }

      target_env=""

      set_env() {
        if [[ -n "$target_env" ]]; then
          echo "Error: Mutually exclusive flags provided. Choose either --prod or --stag." >&2
          exit 1
        fi
        target_env=$1
      }

      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          --prod) set_env prod ;;
          --stag) set_env stag ;;
          *)
            echo "Error: Unknown option '$1'. Use --stag or --prod." >&2
            exit 1
            ;;
        esac
        shift
      done

      # Default to staging if no flag is provided
      target_env=''${target_env:-stag}
      case "$target_env" in
        stag) idp_account=$(< ${config.age.secrets.${idpSecretName "staging"}.path}) ;;
        prod) idp_account=$(< ${config.age.secrets.${idpSecretName "prod"}.path}) ;;
      esac

      SAML2AWS_USERNAME=$(op read "op://${cfg.onePassword.vault}/${cfg.onePassword.item}/username")
      SAML2AWS_PASSWORD=$(op read "op://${cfg.onePassword.vault}/${cfg.onePassword.item}/password")
      SAML2AWS_MFA_TOKEN=$(op item get "${cfg.onePassword.item}" --vault "${cfg.onePassword.vault}" --otp)
      export SAML2AWS_USERNAME SAML2AWS_PASSWORD SAML2AWS_MFA_TOKEN

      echo "Connecting with SAML as $SAML2AWS_USERNAME for environment: $target_env"

      saml2aws login --idp-account="$idp_account" --force
    '';
  };
in
{
  options.hostModules.jumpcloud = {
    enable = mkEnableOption "JumpCloud (SAML) OpenVPN profiles via openvpn3";

    user = mkOption {
      type = lib.types.str;
      description = "User who starts the sessions; openvpn3 runs as them and must read the .ovpn files.";
    };

    profiles = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "staging"
        "prod"
      ];
      description = ''
        One `jumpcloud-vpn <profile>` target per entry, read from
        `jumpcloud_<profile>_ovpn.age` in the nix-secrets input.
      '';
    };

    onePassword = {
      vault = mkOption {
        type = lib.types.str;
        default = "Employee";
        description = "1Password vault holding the JumpCloud login used by `jumpcloud-aws`.";
      };

      item = mkOption {
        type = lib.types.str;
        default = "JumpCloud";
        description = "1Password item (username, password and OTP) used by `jumpcloud-aws`.";
      };
    };
  };

  config = mkIf cfg.enable {
    # The NetworkManager OpenVPN plugin can't do the web (SAML) login JumpCloud
    # requires (`AUTH_FAILED ... IV_SSO=webauth`); openvpn3 can.
    programs.openvpn3.enable = true;

    networking.networkmanager.plugins = [
      pkgs.networkmanager-openvpn
    ];

    # Shouldn't be really here, but no better place to put this yet
    programs._1password = {
      enable = true;
    };

    programs._1password-gui = {
      enable = true;
    };

    # openvpn3's netcfg service (v27.1) dies on startup without
    # org.freedesktop.resolve1, even with `systemd_resolved = false`. With
    # resolved running, programs.openvpn3 turns that integration on and
    # NetworkManager switches its DNS backend to it automatically.
    services.resolved.enable = true;

    # The .ovpn files exported from the VPN portal, as-is (they embed the CA and
    # TLS key). Owned by the user because openvpn3 reads them as the caller.
    # The saml2aws idp-account names used by `jumpcloud-aws` are secrets as well.
    age.secrets =
      lib.genAttrs
        (
          map secretName cfg.profiles
          ++ map idpSecretName [
            "staging"
            "prod"
          ]
        )
        (name: {
          file = "${inputs.nix-secrets}/${name}.age";
          owner = cfg.user;
          mode = "0400";
        });

    environment.systemPackages = [
      jumpcloudVpn
      jumpcloudAws
    ];
  };
}
