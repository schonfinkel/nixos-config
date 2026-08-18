local opt = vim.opt
local g = vim.g

vim.cmd [[
    set nowrap
    set nobackup
    set nowritebackup
    set noerrorbells
    set noswapfile
]]

-------
-- Maps
-------
-- I define most of my shortcuts in different files, this section contains
-- only the generic ones.
vim.keymap.set("n", " ", "<Nop>", { silent = true, remap = false })
g.mapleader = " "

vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- I always forget the regex replace syntax
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Cancel search highlighting with ESC
vim.keymap.set("n", "<ESC>", ":nohlsearch<Bar>:echo<CR>")

--------------
-- Performance
opt.lazyredraw = true;
opt.shell = "zsh"

-- Colors
opt.termguicolors = true

-- Undo files
opt.undofile = true

-- Indentation
opt.smartindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.expandtab = true
opt.scrolloff = 8

-- Set clipboard to use system clipboard
opt.clipboard = "unnamedplus"

-- Nicer UI settings
opt.cursorline = true
opt.relativenumber = true
opt.number = true

-- Get rid of annoying viminfo file
opt.viminfo = ""
opt.viminfofile = "NONE"

-- Load per-project .nvim.lua files (used e.g. for DAP/build overrides).
-- Only open trusted repositories: this executes project-local Lua.
opt.exrc = true

-- Miscellaneous quality of life
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true
opt.ttimeoutlen = 5
opt.smartcase = true

opt.compatible = false
opt.hidden = true
opt.shortmess = "atI"

-- Autoclose
require("autoclose").setup()

-- Comment
require('Comment').setup({})

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>lg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>gf', builtin.git_files, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Eyecandy
require 'colorizer'.setup({})

require 'nvim-web-devicons'.setup {
    -- your personnal icons can go here (to override)
    -- you can specify color or cterm_color instead of specifying both of them
    -- DevIcon will be appended to `name`
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    -- globally enable different highlight colors per icon (default to true)
    -- if set to false all icons will have the default icon's color
    color_icons = true,
    -- globally enable default icons (default to false)
    -- will get overriden by `get_icons` option
    default = true,
}

-- Snacks (required by opencode.nvim for the prompt UI)
require("snacks").setup({
    input = { enabled = true },
    picker = { enabled = true },
})

-- Open Code
---@type opencode.Opts
vim.g.opencode_opts = {}
opencode = require("opencode")

vim.keymap.set("n", "<leader>oa", function() require("opencode").ask() end,
    { desc = "Opencode: ask" })
vim.keymap.set("n", "<leader>oA", function() require("opencode").ask("@cursor: ") end,
    { desc = "Opencode: ask about this" })
vim.keymap.set("v", "<leader>oa", function() require("opencode").ask("@selection: ") end,
    { desc = "Opencode: ask about selection" })
vim.keymap.set("n", "<leader>ot", function() require("opencode").toggle() end,
    { desc = "Opencode: toggle embedded" })
vim.keymap.set("n", "<leader>on", function() require("opencode").command("session_new") end,
    { desc = "Opencode: new session" })
vim.keymap.set("n", "<leader>oy", function() require("opencode").command("messages_copy") end,
    { desc = "Opencode: copy last message" })
vim.keymap.set("n", "<leader>op", function() require("opencode").select_prompt() end,
    { desc = "Opencode: select prompt" })
vim.keymap.set({ "n", "v" }, "<leader>oe", function() require("opencode").prompt("Explain @cursor and its context") end,
    { desc = "Opencode: explain code" })
