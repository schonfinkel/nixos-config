{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.noctalia;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    ;
in
{
  # programs.noctalia comes from Home Manager itself. The noctalia flake's
  # homeModules.default duplicates it and its `disabledModules` no longer
  # matches HM's path (programs/noctalia/default.nix), so importing both breaks.

  options.homeModules.noctalia = {
    enable = mkEnableOption "Enable Noctalia shell (bar, launcher, notifications, wallpaper)";

    timeZone = mkOption {
      type = lib.types.str;
      default = "America/Cuiaba";
    };

    caffeineOnStartup = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Turn on the idle inhibitor (caffeine) whenever Noctalia starts.";
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia = {
      enable = true;

      # The systemd user service is bound to graphical-session.target by the
      # Home Manager module, so it starts inside the uwsm-managed Hyprland
      # session. `launch_apps_as_systemd_services` is only honoured when
      # Noctalia runs under the systemd user manager, which is exactly this case.
      systemd.enable = true;

      # Theme (palette, wallpaper, font, opacity, mode) is driven by stylix's
      # native noctalia target (see home/themes.nix), so none of those keys are
      # set here.
      settings = {
        shell = {
          launch_apps_as_systemd_services = true;
        };

        theme = {
          templates = {
            # Render the Noctalia palette into an Emacs theme (see
            # dotfiles/emacs.d/ui.el).
            enable_builtin_templates = true;
            builtin_ids = [ "emacs" ];
          };
        };

        # Noctalia is the notification daemon now that mako is gone.
        notification = {
          enable_daemon = true;
        };

        bar = {
          default = {
            position = "top";
            # Span the full width of the screen, flush against the top edge.
            margin_ends = 0;
            margin_edge = 0;
            start = [
              "launcher"
              "battery"
              "volume"
              "keyboard_layout"
              "caffeine"
              "tray"
            ];
            center = [ "workspaces" ];
            end = [
              "notifications"
              "network"
              "cpu"
              "ram"
              "disk"
              "session"
              "control-center"
              "clock"
            ];
          };
        };

        # sysmon shows one stat per widget, so cpu/memory/disk are three named
        # instances of the same widget type.
        widget = {
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
          };
          ram = {
            type = "sysmon";
            stat = "ram_used";
          };
          disk = {
            type = "sysmon";
            stat = "disk_used_pct";
            path = "/nix";
          };
          network = {
            # Show the network and VPN glyphs side by side, with the VPN name.
            vpn_status = "both";
            show_vpn_label = true;
          };
          clock = {
            format = "{:%H:%M}";
            tooltip_format = "{:%A, %B %d}";
            timezone = cfg.timeZone;
          };
        };
      };
    };

    # Caffeine has no config key and its state isn't persisted, so flip it on
    # over IPC once the shell is up. `noctalia msg` exits 1 until the socket
    # exists, hence the retry loop.
    systemd.user.services.noctalia-caffeine = mkIf cfg.caffeineOnStartup {
      Unit = {
        Description = "Enable Noctalia caffeine (idle inhibitor) on startup";
        After = [ "noctalia.service" ];
        PartOf = [ "noctalia.service" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "noctalia-caffeine-enable" ''
          for _ in $(seq 30); do
            ${lib.getExe config.programs.noctalia.package} msg caffeine-enable && exit 0
            sleep 1
          done
          exit 1
        '';
      };

      Install.WantedBy = [ "noctalia.service" ];
    };
  };
}
