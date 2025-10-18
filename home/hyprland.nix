{
  config,
  lib,
  pkgs,
  ...
}:

let
  module_name = "homeModules.hyprland";
  cfg = config."${module_name}";
  themes_module = config.homeModules.themes;
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  # hyprpaper
  path = ../wallpapers;
  files = builtins.attrNames (builtins.readDir path);
  format = (
    p:
    builtins.concatStringsSep "/" [
      (builtins.toString path)
      p
    ]
  );
  wallpapers = map format files;
in
{
  options = {
    "${module_name}" = {
      enable = mkEnableOption "Home manager settings for 'Hyprland'";

      timeZone = mkOption {
        type = lib.types.str;
        default = "America/Cuiaba";
      };

      transitionAnimation = mkOption {
        type = lib.types.str;
        default = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
      };

      wallpapers = mkOption {
        type = lib.types.listOf lib.types.path;
        default = wallpapers;
      };
    };
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = cfg.wallpapers;
      };
    };

    programs.waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
          layer = "top";
          position = "top";
          modules-center = [ "hyprland/workspaces" ];
          modules-left = [
            "custom/startmenu"
            "battery"
            "hyprland/language"
            "idle_inhibitor"
            "tray"
          ];
          modules-right = [
            "custom/notification"
            #"network"
            "pulseaudio"
            "cpu"
            "memory"
            "custom/exit"
            "clock"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              "1" = " ";
              "2" = " ";
              "3" = " ";
              "4" = " ";
              "5" = " ";
              "6" = " ";
              "7" = " ";
              "8" = " ";
              "9" = " ";
              "0" = " ";
              active = "";
              default = "";
              urgent = "";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };

          "clock" = {
            format = "  {:L%H:%M}";
            interval = "30";
            format-alt = "  {%d/%m/%y}";
            tooltip = true;
            tooltip-format = "<tt><big>{calendar}</big></tt>";
            timezone = cfg.timeZone;
            #timezone = config.time.timeZone;
            calendar = {
              mode = "month";
              format = {
                months = "<span color='#${config.stylix.base16Scheme.base04}'><b>{}</b></span>";
                days = "<span color='#${config.stylix.base16Scheme.base05}'><b>{}</b></span>";
                weeks = "<span color='#${config.stylix.base16Scheme.base07}'><b>W{}</b></span>";
                weekdays = "<span color='#${config.stylix.base16Scheme.base06}'><b>{}</b></span>";
                today = "<span color='#${config.stylix.base16Scheme.base0A}'><b><u>{}</u></b></span>";
              };
            };
          };

          "memory" = {
            interval = 5;
            format = "  {}%";
            tooltip = true;
            tooltip-format = "  {used:0.1f}G/{total:0.1f}G";
          };

          "cpu" = {
            interval = 5;
            format = "  {usage:2}%";
            tooltip = true;
          };

          "disk" = {
            format = " {free}";
            tooltip = true;
          };

          "hyprland/language" = {
            format = "{}";
            format-en = "🇺🇸";
            format-br = "🇧🇷";
            on-click = "hyprctl switchxkblayout at-translated-set-2-keyboard next";
          };

          "network" = {
            format-icons = [
              "󰤯 "
              "󰤟 "
              "󰤢 "
              "󰤥 "
              "󰤨 "
            ];
            format-ethernet = "  {ipaddr}/{cidr}";
            format-wifi = "  {essid} ({signalStrength}%)";
            format-disconnected = "󰤮 ";
            tooltip = true;
            tooltip-format-ethernet = "{ifname} via {gwaddr}";
            tooltip-format-wifi = "  {essid} ({signalStrength}%)";
            on-click = "sleep 0.1 && nm-applet";
          };

          "tray" = {
            spacing = 12;
          };

          "pulseaudio" = {
            format = "{icon}  {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = " {volume}%";
            format-source-muted = " ";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "sleep 0.1 && pavucontrol";
          };

          "custom/exit" = {
            tooltip = false;
            format = " ";
            on-click = "sleep 0.1 && wlogout";
          };

          "custom/startmenu" = {
            tooltip = false;
            format = " ";
            on-click = "sleep 0.1 && wofi --dmenu";
          };

          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = "true";
          };

          "custom/notification" = {
            tooltip = false;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='#${config.stylix.base16Scheme.base02}'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='#${config.stylix.base16Scheme.base02}'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='#${config.stylix.base16Scheme.base02}'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='#${config.stylix.base16Scheme.base02}'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which mako";
            exec = "swaync-client -swb";
            on-click = "sleep 0.1 && task-waybar";
            escape = true;
          };

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            on-click = "";
            tooltip = false;
          };
        }
      ];
      style = pkgs.lib.concatStrings [
        ''
          * {
            font-family: JetBrainsMono Nerd Font Mono;
            font-size: 24px;
            border-radius: 0px;
            border: none;
            min-height: 0px;
          }

          window#waybar {
            background: rgba(0,0,0,0);
          }

          #workspaces {
            color: #${config.stylix.base16Scheme.base04};
            background: #${config.stylix.base16Scheme.base01};
            margin: 2px 2px;
            padding: 3px 3px;
            border-radius: 4px;
          }

          #workspaces button {
            font-weight: bold;
            padding: 0px 2px;
            margin: 0px 3px;
            border-radius: 8px;
            color: #${config.stylix.base16Scheme.base04};
            background: #${config.stylix.base16Scheme.base01};
            opacity: 0.5;
            transition: ${transitionAnimation};
          }

          #workspaces button.active {
            font-weight: bold;
            padding: 0px 5px;
            margin: 0px 3px;
            border-radius: 4px;
            color: #${config.stylix.base16Scheme.base00};
            background: #${config.stylix.base16Scheme.base07};
            transition: ${transitionAnimation};
            opacity: 1.0;
            min-width: 20px;
          }

          #workspaces button.focused {
            border-bottom: 3px solid #${config.stylix.base16Scheme.base04};
          }

          #workspaces button.urgent {
            color: #${config.stylix.base16Scheme.base09};
            border-bottom: 3px solid #${config.stylix.base16Scheme.base06};
          }

          #workspaces button:hover {
            font-weight: bold;
            border-radius: 16px;
            color: #${config.stylix.base16Scheme.base00};
            background: #${config.stylix.base16Scheme.base07};
            opacity: 0.8;
            transition: ${transitionAnimation};
          }

          tooltip {
            background: #${config.stylix.base16Scheme.base00};
            border: 1px solid #${config.stylix.base16Scheme.base04};
            border-radius: 12px;
          }

          tooltip label {
            color: #${config.stylix.base16Scheme.base04};
          }

          #pulseaudio,
          #network,
          #cpu,
          #memory,
          #disk,
          #tray, 
          #idle_inhibitor {
            font-weight: bold;
            margin: 4px 0px;
            margin-right: 5px;
            padding: 0px 12px;
            background: #${config.stylix.base16Scheme.base03};
            color: #${config.stylix.base16Scheme.base00};
            border-radius: 24px 10px 24px 10px;
          }

          #custom-startmenu {
            color: #${config.stylix.base16Scheme.base00};
            background: #${config.stylix.base16Scheme.base05};
            font-size: 22px;
            margin: 0px;
            margin-right: 5px;
            padding: 0px 20px 0px 20px;
            border-radius: 0px 0px 20px 0px;
          }

          #battery,
          #hyprland-language,
          #custom-notification,
          #custom-exit {
            font-weight: bold;
            color: #${config.stylix.base16Scheme.base00};
            background: #${config.stylix.base16Scheme.base03};
            margin: 4px 0px;
            margin-right: 7px;
            border-radius: 24px 10px 24px 10px;
            padding: 0px 18px;
          }

          #clock {
            font-weight: bold;
            background: #${config.stylix.base16Scheme.base05};
            color: #${config.stylix.base16Scheme.base00};
            margin: 0px;
            padding: 0px 15px 0px 30px;
            border-radius: 0px 0px 0px 30px;
          }
        ''
      ];
    };

    xdg.configFile = {
      "hypr" = {
        source = ../dotfiles/hypr;
        recursive = true;
      };
    };
  };
}
