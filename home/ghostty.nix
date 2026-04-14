{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.ghostty;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.ghostty = {
    enable = mkEnableOption "Enable the Ghostty terminal emulator";
    fontSize = mkOption {
      type = lib.types.int;
      default = 16;
    };
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      installVimSyntax = true;

      settings = {
        background-opacity = "0.95";
        command = "zsh";

        font-family = "Terminus";
        font-size = cfg.fontSize;
        font-thicken = true;

        keybind = [
          "super+h=goto_split:left"
          "super+j=goto_split:bottom"
          "super+k=goto_split:top"
          "super+l=goto_split:right"
        ];

        mouse-hide-while-typing = true;

        scrollback-limit = 10000;
        # https://ghostty.org/docs/features/shell-integration#ssh-integration
        shell-integration-features = "ssh-env,ssh-terminfo";
      };

      systemd = {
        enable = true;
      };
    };
  };
}
