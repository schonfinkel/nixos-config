{ pkgs, lib, config, ... }:

let
  dotfiles = f: "${builtins.toString ../../dotfiles/nvim}/${f}.lua";
  vimPlugins = import ./packages.nix { inherit pkgs config lib; };
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = true;

    # https://github.com/nix-community/home-manager/issues/1907#issuecomment-934316296
    extraConfig = builtins.concatStringsSep "\n" [
      ''
      luafile ${dotfiles "settings"}
      luafile ${dotfiles "line"}
      luafile ${dotfiles "lsp"}
      luafile ${dotfiles "cmp"}
      luafile ${dotfiles "tabs"}
      luafile ${dotfiles "git"}
      luafile ${dotfiles "files"}
      luafile ${dotfiles "treesitter"}
      ''
    ];

    extraPackages = with pkgs; [
      clang
      tree-sitter
    ];

    plugins = builtins.concatLists [
      vimPlugins.base
      vimPlugins.eyecandy
      vimPlugins.ui
      vimPlugins.lsp
      vimPlugins.prv
      vimPlugins.tooling
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
}
