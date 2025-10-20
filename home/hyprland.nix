{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.hyprland;
  stylix_theme = config.stylix.base16Scheme;
  stylix_colors = lib.stylix.colors.withHashtag;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
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
  options.homeModules.hyprland = {
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

          modules-left = [
            "custom/startmenu"
            "battery"
            "pulseaudio"
            "hyprland/language"
            "idle_inhibitor"
            "tray"
          ];

          modules-center = [ 
            "hyprland/workspaces"
          ];

          modules-right = [
            "custom/notification"
            "network"
            "cpu"
            "memory"
            "disk"
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
            # on-click = "neohtop";
            tooltip = true;
            tooltip-format = "  {used:0.1f}G/{total:0.1f}G";
          };

          "cpu" = {
            interval = 5;
            format = "  {usage:2}%";
            # on-click = "neohtop";
            tooltip = true;
          };

          "disk" = {
            format = " {free}";
            # on-click = "neohtop";
            tooltip = true;
          };

          "hyprland/language" = {
            format = "󰌌 {short}";
            format-en = "🇺🇸";
            format-br = "🇧🇷";
            on-click = "hyprctl switchxkblayout at-translated-set-2-keyboard next";
            tooltip-format = "󰌌 {long}";
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
          @define-color base00 ${stylix_colors.base00}; 
          @define-color base01 ${stylix_colors.base01};
          @define-color base02 ${stylix_colors.base02};
          @define-color base03 ${stylix_colors.base03};
          @define-color base04 ${stylix_colors.base04};
          @define-color base05 ${stylix_colors.base05};
          @define-color base06 ${stylix_colors.base06};
          @define-color base07 ${stylix_colors.base07};
          @define-color base08 ${stylix_colors.base08};
          @define-color base09 ${stylix_colors.base09};
          @define-color base0A ${stylix_colors.base0A};
          @define-color base0B ${stylix_colors.base0B};
          @define-color base0C ${stylix_colors.base0C};
          @define-color base0D ${stylix_colors.base0D};
          @define-color base0E ${stylix_colors.base0E};
          @define-color base0F ${stylix_colors.base0F};

          @define-color bg1 ${stylix_colors.base00};
          @define-color bg2 ${stylix_colors.base01};
          @define-color bg-hover ${stylix_colors.base0A};

          @define-color border1 ${stylix_colors.base03};
          @define-color border2 ${stylix_colors.base0F};
          @define-color border-alt ${stylix_colors.base0E};

          @define-color text ${stylix_colors.base05};
          @define-color text-alt ${stylix_colors.base0D};
          @define-color subtext ${stylix_colors.base04};

          @define-color critical ${stylix_colors.base08};
          @define-color warning ${stylix_colors.base09};
          @define-color success ${stylix_colors.base0B};
          @define-color info ${stylix_colors.base0C};
        ''
        ''
          * {
            border: none;
            border-radius: 0;
            font-family: 'JetBrains Mono', 'Hack Nerd Font', 'UbuntuMono', monospace;
            font-size: 14px;
            font-weight: 600;
            min-height: 0;
            padding: 0;
            margin: 0;
          }

          window#waybar {
            background: @bg1;
            border-bottom: 1px solid @border1;
          }

          /* Tooltips */
          tooltip {
            background: @bg2;
            color: @text;
            border: 1px solid @border2;
            border-radius: 8px;
            padding: 8px 12px;
          }

          tooltip label {
            color: @text;
            font-size: 12px;
          }

          /* Workspaces */
          #workspaces {
          	background: @bg1;
          	padding: 4px;
          	margin: 6px 2px;
          	border-radius: 12px;
          	border: 2px solid @border1;
          }
          
          #workspaces button {
          	padding: 6px 10px;
          	margin: 0 2px;
          	background: @bg1;
          	color: @text;
          	border-radius: 8px;
          	font-weight: bold;
          	border: 1px solid @border1;
          }
          
          #workspaces button:hover {
          	background: @bg-hover;
          	color: @subtext;
          	border-color: @border2;
            transition: ${cfg.transitionAnimation};
          }
          
          #workspaces button.active,
          #workspaces button.focused {
          	background: @bg2;
          	color: @subtext;
          	font-weight: bold;
          	opacity: 1;
          	border-color: @border2;
          }
          
          #workspaces button.empty {
          	opacity: 0.3;
            background: @bg2;
          }
          
          #workspaces button.urgent {
          	background: @error;
          	color: @text;
          	border-color: @bg2;
          }

          #window {
            background: @bg2;
            color: @text;
            padding: 8px 16px;
            border-radius: 12px;
            border: 1px solid @border2;
            font-weight: 500;
          }

          /* System Metrics */
          #disk,
          #memory {
            background: @bg1;
            color: @text;
            border-left: 4px solid @border1;
            border-radius: 12px 0 0 12px;
            margin: 6px 0;
            padding: 8px 12px;
          }
          
          #cpu {
            background: @bg1;
            color: @text;
            border-left: 4px solid @border1;
            margin: 6px 0px 6px 0;
            padding: 8px 12px;
          }

          /* Battery */
          #battery {
          	background: @bg1;
          	color: @text;
          	border-left: 4px solid @border1;
          	margin: 6px 2px;
          	padding: 8px 12px;
          	border-radius: 12px;
          }
          
          #battery.charging {
          	color: @text-alt;
          	border-left: 4px solid @border-alt;
          }
          
          #battery.warning {
          	background: @warning;
          	color: @text-alt;
          	border-left: 4px solid @warning;
          }
          
          #battery.critical:not(.charging) {
          	background: @error;
          	color: @bg2;
          	border-left: 4px solid @border-alt;
          }

          /* Audio */
          #pulseaudio {
            background: @bg2;
            color: @text;
            border-left: 4px solid @border1;
            border-radius: 0 12px 12px 0;
            margin: 6px 2px 6px 0;
            padding: 8px 12px;
          }
          
          #pulseaudio.muted {
            color: @subtext;
            border-left: 4px solid @subtext;
          }

          /* Network */
          #network {
            background: @bg2;
            color: @text-alt;
            border-left: 4px solid @border2;
            margin: 6px 2px;
            padding: 8px 12px;
            border-radius: 12px;
          }
          
          #network.disconnected {
            color: @error;
            border-left: 4px solid @error;
          }
          
          #network.disabled {
            color: @subtext;
            border-left: 4px solid @subtext;
          }

          /* Language & Keyboard */
          #hyprland-language {
            background: @bg1;
            color: @text;
            border-left: 4px solid @border1;
            margin: 6px 0 6px 2px;
            padding: 8px 12px;
            border-radius: 12px 0 0 12px;
          }

          /* System Tray */
          #tray {
            background: @bg2;
            padding: 6px 10px;
            margin: 6px 8px 6px 2px;
            border-radius: 12px;
            border: 1px solid @border2;
          }
          
          #tray > .passive {
            opacity: 0.7;
          }
          
          #tray > .needs-attention {
            background-color: @error;
            border-radius: 6px;
            color: @text-alt;
          }

          /* Clock */
          #clock {
            background: @bg2;
            color: @subtext;
            font-weight: bold;
            margin: 6px 2px 6px 2px;
            padding: 8px 12px;
            border-radius: 12px;
            font-size: 15px;
          }

          /* Custom Modules */
          #custom-exit,
          #custom-notification,
          #custom-startmenu {
            background: @bg1;
            color: @text-alt;
            border-left: 4px solid @border1;
            margin: 6px 2px;
            padding: 8px 12px;
            border-radius: 12px;
          }

          /* Idle Inhibitor */
          #idle_inhibitor {
            background: @bg1;
            color: @text;
            border-left: 4px solid @border1;
            margin: 6px 2px;
            padding: 8px 12px;
            border-radius: 12px;
          }
          
          #idle_inhibitor.activated {
            background: @bg2;
            border-left: 4px solid @border2;
            color: @subtext;
          }

          /* Hover Effects */
          #clock:hover,
          #battery:hover,
          #cpu:hover,
          #memory:hover,
          #network:hover,
          #pulseaudio:hover,
          #custom-notification:hover,
          #custom-startmenu:hover,
          #language:hover {
            opacity: 0.8;
          }
        ''
      ];

    xdg.configFile = {
      "hypr" = {
        source = ../dotfiles/hypr;
        recursive = true;
      };
    };
  };
}
