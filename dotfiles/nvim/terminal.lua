require("floaterm").setup({
    width = 0.8,
    height = 0.8,
    border = "rounded",
})

-- Toggle / Untoggle Keymaps
-- Normal mode: Toggle terminal
vim.keymap.set("n", [[<C-\>]], "<cmd>Floaterm<CR>", { silent = true })

-- Terminal mode: Untoggle terminal
-- We escape to normal mode (<C-\><C-n>) then call the command to hide it
vim.keymap.set("t", [[<C-\>]], [[<C-\><C-n><cmd>Floaterm<CR>]], { silent = true })
