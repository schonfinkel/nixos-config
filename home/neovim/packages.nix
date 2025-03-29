{ pkgs, config, lib, ... }:

let
  plugins = pkgs.vimPlugins;
  private = import ./private.nix { inherit pkgs config; };
in
{
  base = with plugins; [
    autoclose-nvim
    hologram-nvim
    toggleterm-nvim
    vim-which-key
    vim-visual-multi
  ];
  eyecandy = with plugins; [
    kanagawa-nvim
    nvim-colorizer-lua
    nvim-cursorline
    nvim-web-devicons
    tokyonight-nvim
  ];
  ui = with plugins; [
    # File Tree
    nvim-tree-lua
    # Find/Filter
    plenary-nvim
    telescope-nvim
    # Status Line
    lualine-nvim
    # Tabs
    barbar-nvim
  ];
  lsp = with plugins // private; [
    nvim-cmp
    nvim-lspconfig
    (nvim-treesitter.withPlugins (p:
      [
        p.c
        p.bash
        p.dockerfile
        p.erlang
        p.elixir
        p.gitignore
        p.gleam
        p.haskell
        p.json
        p.just
        p.latex
        p.lua
        p.make
        p.markdown
        p.nix
        p.ocaml
        p.proto
        p.scheme
        p.sql
        p.terraform
        p.yaml
      ]
    ))
    # Snippets
    luasnip
    cmp-git
    # CMP Plugins
    cmp-cmdline
    cmp_luasnip
    cmp-nvim-lsp
    cmp-path
    cmp-treesitter
  ];
  prv = with private; [ vim-taskjuggler ];
  tooling = with plugins; [
    direnv-vim
    gitsigns-nvim
    gleam-vim
    neogit
    Ionide-vim
    vim-just
    vim-nix
    vim-terraform
  ];
}
