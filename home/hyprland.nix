{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.hyprland;
  stylix_theme = config.stylix.base16Scheme;
  stylix_colors = config.lib.stylix.colors.withHashtag;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
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

    hyprlock = {
      enable = mkEnableOption "Enable a custom 'hyprlock' configuration" // {
        default = true;
      };
    };

    waybar = {
      enable = mkEnableOption "Enable a custom 'waybar' configuration" // {
        default = true;
      };

      timeZone = mkOption {
        type = lib.types.str;
        default = "America/Cuiaba";
      };

      transitionAnimation = mkOption {
        type = lib.types.str;
        default = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
      };
    };

    wallpapers = mkOption {
      type = lib.types.listOf lib.types.path;
      default = wallpapers;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.hyprpaper = {
        enable = true;
        settings = {
          preload = cfg.wallpapers;
        };
      };

      services.mako.enable = true;

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;

        settings = {
          # Monitors
          monitor = [
            "HDMI-A-1,highres,0x0,2"
            "eDP-1,highres,1920x0,1"
          ];

          # Programs
          "$terminal" = "${lib.getExe pkgs.kitty}";
          "$fileManager" = "${lib.getExe pkgs.ranger}";
          # "$lock" = "hyprlock";
          "$menu" = "wofi --show drun";
          "$mainMod" = "SUPER";

          # Autostart
          exec-once = [
            "nm-applet"
            "waybar"
            "hyprpaper"
          ];

          # Environment variables
          env = [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
            "WLR_NO_HARDWARE_CURSORS,1"
            "QT_AUTO_SCREEN_SCALE_FACTOR,2"
            "QT_QPA_PLATFORM,wayland;xcb"
            "QT_QPA_PLATFORMTHEME,q6ct"
            "QT_SCALE_FACTOR,2"
            "GDK_SCALE,2"
            "XDG_SESSION_DESKTOP,Hyprland"
            "XDG_SESSION_TYPE,wayland"
            "XDG_CURRENT_DESKTOP,Hyprland"
            "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
            "GDK_BACKEND,wayland"
            "ELECTRON_OZONE_PLATFORM_HINT,wayland"
            "NIXOS_OZONE_WL,1"
            "MOZ_ENABLE_WAYLAND,1"
            "WAYLAND_DISPLAY,wayland-0"
          ];

          # General settings
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };

          # Decoration
          decoration = {
            rounding = 0;
            active_opacity = 1.0;
            inactive_opacity = 1.0;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
            };

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          # Animations
          animations = {
            enabled = true;

            bezier = [
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
            ];

            animation = [
              "global,1,10,default"
              "border,1,5.39,easeOutQuint"
              "windows,1,4.79,easeOutQuint"
              "windowsIn,1,4.1,easeOutQuint,popin 87%"
              "windowsOut,1,1.49,linear,popin 87%"
              "fadeIn,1,1.73,almostLinear"
              "fadeOut,1,1.46,almostLinear"
              "fade,1,3.03,quick"
              "layers,1,3.81,easeOutQuint"
              "layersIn,1,4,easeOutQuint,fade"
              "layersOut,1,1.5,linear,fade"
              "fadeLayersIn,1,1.79,almostLinear"
              "fadeLayersOut,1,1.39,almostLinear"
              "workspaces,1,1.94,almostLinear,fade"
              "workspacesIn,1,1.21,almostLinear,fade"
              "workspacesOut,1,1.94,almostLinear,fade"
            ];
          };

          # Dwindle layout
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          # Master layout
          master = {
            new_status = "master";
          };

          # XWayland
          xwayland = {
            force_zero_scaling = true;
            use_nearest_neighbor = true;
          };

          # Input
          input = {
            kb_layout = "us,br(thinkpad)";
            kb_options = "grp:win_space_toggle";
            follow_mouse = 1;
            sensitivity = 0;

            touchpad = {
              natural_scroll = false;
            };
          };

          # Device specific config
          device = {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          };

          # Keybindings
          bind = [
            # Applications
            "$mainMod,Return,exec,$terminal"
            "$mainMod SHIFT,Q,killactive,"
            "$mainMod,E,exec,$fileManager"
            "$mainMod,D,exec,$menu"
            # "$mainMod SHIFT,L,$lock"

            # Window management
            "$mainMod,P,pseudo,"
            "$mainMod,J,togglesplit,"
            "$mainMod,F,togglefloating,"
            "$mainMod SHIFT,F,fullscreen"

            # Focus movement
            "$mainMod,left,movefocus,l"
            "$mainMod,right,movefocus,r"
            "$mainMod,up,movefocus,u"
            "$mainMod,down,movefocus,d"

            # Workspace switching
            "$mainMod,1,workspace,1"
            "$mainMod,2,workspace,2"
            "$mainMod,3,workspace,3"
            "$mainMod,4,workspace,4"
            "$mainMod,5,workspace,5"
            "$mainMod,6,workspace,6"
            "$mainMod,7,workspace,7"
            "$mainMod,8,workspace,8"
            "$mainMod,9,workspace,9"
            "$mainMod,0,workspace,10"

            # Move window to workspace
            "$mainMod SHIFT,1,movetoworkspace,1"
            "$mainMod SHIFT,2,movetoworkspace,2"
            "$mainMod SHIFT,3,movetoworkspace,3"
            "$mainMod SHIFT,4,movetoworkspace,4"
            "$mainMod SHIFT,5,movetoworkspace,5"
            "$mainMod SHIFT,6,movetoworkspace,6"
            "$mainMod SHIFT,7,movetoworkspace,7"
            "$mainMod SHIFT,8,movetoworkspace,8"
            "$mainMod SHIFT,9,movetoworkspace,9"
            "$mainMod SHIFT,0,movetoworkspace,10"

            # Special workspace
            "$mainMod,S,togglespecialworkspace,magic"
            "$mainMod SHIFT,S,movetoworkspace,special:magic"

            # Scroll through workspaces
            "$mainMod,mouse_down,workspace,e+1"
            "$mainMod,mouse_up,workspace,e-1"

            # Window resizing
            "$mainMod SHIFT,right,resizeactive,10 0"
            "$mainMod SHIFT,left,resizeactive,-10 0"
            "$mainMod SHIFT,up,resizeactive,0 -10"
            "$mainMod SHIFT,down,resizeactive,0 10"

            # Screenshot
            ",PRINT,exec,hyprshot -m region"
          ];

          # Mouse bindings
          bindm = [
            "$mainMod,mouse:272,movewindow"
            "$mainMod,mouse:273,resizewindow"
          ];

          # Media keys with repeat
          bindel = [
            ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",XF86AudioMicMute,exec,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ",XF86MonBrightnessUp,exec,brightnessctl s 10%+"
            ",XF86MonBrightnessDown,exec,brightnessctl s 10%-"
          ];

          # Media control keys
          bindl = [
            ",XF86AudioNext,exec,playerctl next"
            ",XF86AudioPause,exec,playerctl play-pause"
            ",XF86AudioPlay,exec,playerctl play-pause"
            ",XF86AudioPrev,exec,playerctl previous"
          ];

          # Window rules
          windowrule = [
            "match:class .*, suppress_event maximize"
            "match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus 1"

            # NetworkManager applet
            "match:class ^(nm-connection-editor)$, float true, size $floatingSize, move center center"

            # Special Workspaces
            # "match:class ^(discord)$, workspace special:discord"

            # XWayland video bridge fixes
            "match:class ^(xwaylandvideobridge)$, opacity 0.0 override, no_anim 1, no_initial_focus 1, max_size 1 1, no_blur 1, no_focus 1"
          ];
        };
      };
    }

    # Hyprlock Configuration
    (mkIf cfg.hyprlock.enable {
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            disable_loading_bar = true;
            hide_cursor = true;
          };

          background = lib.mkForce [
            {
              monitor = "";
              path = builtins.head cfg.wallpapers;
              color = "rgb(${stylix_theme.base00})";
              blur_passes = 1;
              blur_size = 1;
              new_optimizations = true;
              ignore_opacity = false;
            }
          ];

          input-field = lib.mkOverride 10 [
            {
              monitor = "";
              size = "300, 50";
              outline_thickness = 2;
              fade_on_empty = false;
              placeholder_text = "<i>Enter Password</i>";
              dots_spacing = 0.2;
              dots_center = true;
              position = "0, 125";
              valign = "bottom";
              halign = "center";
            }
          ];

          label = [
            {
              monitor = "";
              text = "cmd[update:3600000] date +'%A, %B %d'";
              font_family = "GeistMono Nerd Font Propo Bold";
              font_size = 36;
              color = "rgb(${stylix_theme.base0E})";
              position = "0, -150";
              valign = "top";
              halign = "center";
            }
            {
              monitor = "";
              text = "$TIME";
              font_family = "GeistMono Nerd Font Propo Bold";
              font_size = 132;
              color = "rgb(${stylix_theme.base0E})";
              position = "0, -200";
              valign = "top";
              halign = "center";
            }
            {
              monitor = "";
              text = "   $USER";
              font_family = "GeistMono Nerd Font Propo Bold";
              font_size = 24;
              color = "rgb(${stylix_theme.base0E})";
              position = "0, 200";
              valign = "bottom";
              halign = "center";
            }
          ];
        };
      };

      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = lib.getExe config.programs.hyprlock.package;
            before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = [
            {
              timeout = 300;
              on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
            }
            {
              timeout = 330;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
            {
              timeout = 600;
              on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
            }
          ];
        };
      };

    })

    # Waybar Configuration
    (mkIf cfg.waybar.enable {
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
              timezone = cfg.waybar.timeZone;
              calendar = {
                mode = "month";
                format = {
                  months = "<span color='#${stylix_theme.base04}'><b>{}</b></span>";
                  days = "<span color='#${stylix_theme.base05}'><b>{}</b></span>";
                  weeks = "<span color='#${stylix_theme.base07}'><b>W{}</b></span>";
                  weekdays = "<span color='#${stylix_theme.base06}'><b>{}</b></span>";
                  today = "<span color='#${stylix_theme.base0F}'><b><u>{}</u></b></span>";
                };
              };
            };

            "memory" = {
              interval = 5;
              format = " {percentage}%";
              tooltip = true;
              tooltip-format = "  {used:0.1f}G/{total:0.1f}G";
              # on-click = "neohtop";
            };

            "cpu" = {
              interval = 5;
              format = " {usage:2}%";
              tooltip = true;
              # on-click = "neohtop";
            };

            "disk" = {
              format = " {percentage_used:2}%";
              path = "/nix";
              tooltip = true;
              tooltip-format = "{used} / {total} on {path}";
              # on-click = "neohtop";
            };

            "hyprland/language" = {
              format = "{}";
              format-en = "🇺🇸";
              format-pt = "🇧🇷";
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
              tooltip-format-ethernet = "{ifname} via {gwaddr}";
              tooltip-format-wifi = "  {essid} ({signalStrength}%)";
              on-click = "sleep 0.1 && nm-applet";
              tooltip = true;
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
              format = " ";
              on-click = "sleep 0.1 && wlogout";
              tooltip = false;
            };

            "custom/startmenu" = {
              format = " ";
              on-click = "sleep 0.1 && wofi --dmenu";
              tooltip = false;
            };

            "idle_inhibitor" = {
              format = "{icon}";
              format-icons = {
                activated = "";
                deactivated = "";
              };
              tooltip = true;
            };

            "custom/notification" = {
              tooltip = false;
              format = "{icon} {}";
              format-icons = {
                notification = "<span foreground='#${stylix_theme.base02}'><sup></sup></span>";
                none = "";
                dnd-notification = "<span foreground='#${stylix_theme.base02}'><sup></sup></span>";
                dnd-none = "";
                inhibited-notification = "<span foreground='#${stylix_theme.base02}'><sup></sup></span>";
                inhibited-none = "";
                dnd-inhibited-notification = "<span foreground='#${stylix_theme.base02}'><sup></sup></span>";
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
            @define-color bg2 ${stylix_colors.base0D};
            @define-color bg-hover ${stylix_colors.base0A};

            @define-color border1 ${stylix_colors.base03};
            @define-color border2 ${stylix_colors.base0F};
            @define-color border-alt ${stylix_colors.base0E};

            @define-color text ${stylix_colors.base05};
            @define-color text-alt ${stylix_colors.base00};
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
              background: rgba(0,0,0,0);
            }

            /* Tooltips */
            tooltip {
              background: @bg1;
              color: @text-alt;
              border: 1px solid @border1;
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
              border-radius: 10px;
              border: 2px solid @border1;
              padding: 4px 4px;
              margin: 1px 2px;
            }

            #workspaces button {
              padding: 2px 4px;
              margin: 1px;
              background: @bg1;
              color: @text;
              border-radius: 10px;
              font-weight: bold;
              opacity: 0.8;
            }

            #workspaces button:hover {
              background: @bg-hover;
              color: @subtext;
              border-color: @border-alt;
              transition: ${cfg.waybar.transitionAnimation};
            }

            #workspaces button.active,
            #workspaces button.focused {
              background: @bg2;
              color: @text-alt;
              font-weight: bold;
              opacity: 1;
              border-color: @border-alt;
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

            /* RIGHT */
            /* Clock */
            #clock {
              background: @bg1;
              color: @subtext;
              font-weight: bold;
              border-left: 4px solid @border1;
              font-size: 15px;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            #custom-exit,
            #custom-notification {
              background: @bg1;
              color: @text;
              border-left: 4px solid @border1;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            /* System Metrics */
            #cpu,
            #memory,
            #disk {
              background: @bg1;
              color: @text;
              border-left: 4px solid @border1;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            /* Network */
            #network {
              background: @bg1;
              color: @text;
              border-left: 4px solid @border1;
              border-radius: 12px 0px 0px 12px;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            #network.disconnected {
              color: @error;
              border-left: 4px solid @error;
            }

            #network.disabled {
              color: @subtext;
              border-left: 4px solid @subtext;
            }

            /* LEFT */
            /* Custom Modules */
            #custom-startmenu {
              background: @bg1;
              color: @text;
              border-right: 4px solid @border1;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            /* Battery */
            #battery {
              background: @bg1;
              color: @text;
              border-right: 4px solid @border1;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            #battery.charging {
              color: @text-alt;
              border-right: 4px solid @border-alt;
            }

            #battery.warning {
              background: @warning;
              color: @text-alt;
              border-right: 4px solid @warning;
            }

            #battery.critical:not(.charging) {
              background: @error;
              color: @bg2;
              border-right: 4px solid @border-alt;
            }

            /* Audio */
            #pulseaudio {
              background: @bg1;
              color: @text;
              border-right: 4px solid @border1;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            #pulseaudio.muted {
              color: @subtext;
              border-right: 4px solid @subtext;
            }

            /* Language & Keyboard */
            #language {
              background: @bg1;
              color: @text;
              border-right: 4px solid @border1;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            /* System Tray */
            #tray {
              background: @bg2;
              border-radius: 0px 12px 12px 0px;
              border: 1px solid @border2;
              margin: 4px 4px 4px 0;
              padding: 8px 8px;
            }

            #tray > .passive {
              opacity: 0.7;
            }

            #tray > .needs-attention {
              background-color: @error;
              border-radius: 6px;
              padding: 8px 8px;
            }

            /* Idle Inhibitor */
            #idle_inhibitor {
              background: @bg1;
              color: @text;
              margin: 4px 0px;
              padding: 8px 8px;
            }

            #idle_inhibitor.activated {
              background: @bg-alt;
              border-right: 4px solid @border2;
              color: @subtext;
            }

            /* Hover Effects */
            #clock:hover,
            #battery:hover,
            #cpu:hover,
            #disk:hover,
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
      };
    })
  ]);
}
