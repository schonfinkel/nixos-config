require("livepreview.config").set({
  port = 5500,
  browser = "default",
  dynamic_root = false,
  sync_scroll = true,
  picker = "telescope",
  address = "127.0.0.1",
})

local map = vim.api.nvim_set_keymap
local options = { noremap = true, silent = true }

map("n", "<Leader>p", ":LivePreview start<CR>", options)
map("n", "<Leader>P", ":LivePreview close<CR>", options)
map("n", "<Leader>pp", ":LivePreview pick<CR>", options)
