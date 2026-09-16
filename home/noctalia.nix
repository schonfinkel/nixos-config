{
  config,
  inputs,
  lib,
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
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.homeModules.noctalia = {
    enable = mkEnableOption "Enable Noctalia shell (bar, launcher, notifications, wallpaper)";

    timeZone = mkOption {
      type = lib.types.str;
      default = "America/Cuiaba";
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
          clock = {
            format = "{:%H:%M}";
            tooltip_format = "{:%A, %B %d}";
            timezone = cfg.timeZone;
          };
        };
      };
    };
  };
}
