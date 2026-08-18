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
      withRuby = false;

      extraConfig = ''
        lua << EOF
          -- Add the XDG config path to the Lua package path
          package.path = package.path .. ";${config.xdg.configHome}/nvim/?.lua"
          
          -- Load modular settings
          require("settings")
          require("line")
          require("lsp")
          require("cmp")
          require("debugging")
          require("tabs")
          require("git")
          require("files")
          require("terminal")
          require("treesitter")
        EOF
      '';

      extraPackages = with pkgs; [
        bash-language-server
        clang
        # Adding ripgrep and fd, for Telescope
        fd
        # lldb ships lldb-dap, used by nvim-dap
        lldb
        # Odin language server + odinfmt formatter
        ols
        ripgrep
        tree-sitter
        # AI shit
        opencode
      ];

      plugins = builtins.concatLists [
        vimPlugins.base
        vimPlugins.debug
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
