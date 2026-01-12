{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.neovim;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;

  vimPlugins = import ./packages.nix { inherit pkgs config lib; };
in
{
  options.homeModules.neovim = {
    enable = mkEnableOption "Enable a custom Neovim configuration";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withPython3 = true;

      extraConfig = ''
        lua << EOF
          -- Add the XDG config path to the Lua package path
          package.path = package.path .. ";${config.xdg.configHome}/nvim/?.lua"
          
          -- Load modular settings
          require("settings")
          require("line")
          require("lsp")
          require("cmp")
          require("tabs")
          require("git")
          require("files")
          require("treesitter")
        EOF
      '';

      extraPackages = with pkgs; [
        bash-language-server
        clang
        # Adding ripgrep and fd, for Telescope
        fd
        ripgrep
        tree-sitter
      ];

      plugins = builtins.concatLists [
        vimPlugins.base
        vimPlugins.eyecandy
        vimPlugins.lsp
        vimPlugins.prv
        vimPlugins.tooling
        vimPlugins.ui
      ];
    };

    xdg.configFile = {
      nvim = {
        source = ../../dotfiles/nvim;
        recursive = true;
      };
    };

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
