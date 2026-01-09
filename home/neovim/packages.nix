{
  pkgs,
  config,
  lib,
  ...
}:

let
  plugins = pkgs.vimPlugins;
  private = import ./private.nix { inherit pkgs config; };
in
{
  base = with plugins; [
    autoclose-nvim
    comment-nvim
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
    (nvim-treesitter.withPlugins (p: [
      p.agda
      p.asm
      p.bash
      p.c
      p.cmake
      p.cpp
      p.css
      p.csv
      p.c_sharp
      p.dockerfile
      p.elixir
      p.erlang
      p.fsharp
      p.gitattributes
      p.gitcommit
      p.gitignore
      p.git_config
      p.git_rebase
      p.gleam
      p.haskell
      p.hcl
      p.hyprlang
      p.idris
      p.json
      p.just
      p.kitty
      p.latex
      p.lua
      p.make
      p.markdown
      p.nix
      p.nginx
      p.ocaml
      p.ocaml_interface
      p.pem
      p.proto
      p.scheme
      p.sql
      p.ssh_config
      p.terraform
      p.unison
      p.yaml
      p.zig
    ]))
    # Snippets
    luasnip
    cmp-git
    # CMP Plugins
    cmp-cmdline
    cmp_luasnip
    cmp-nvim-lsp
    cmp-path
    cmp-treesitter
    # Formatting
    conform-nvim
  ];
  prv = with private; [ vim-taskjuggler ];
  tooling = with plugins; [
    direnv-vim
    gitsigns-nvim
    Ionide-vim
    neogit
    nvim-dbee
    vim-just
    vim-nix
    vim-terraform
  ];
}
