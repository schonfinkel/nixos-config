-- Floating terminal via snacks.nvim
local function toggle_term()
    Snacks.terminal.toggle(nil, {
        win = {
            position = "float",
            border = "rounded",
            width = 0.8,
            height = 0.8,
        },
    })
end

-- Normal mode: toggle terminal
vim.keymap.set("n", [[<C-\>]], toggle_term, { silent = true, desc = "Toggle floating terminal" })

-- Terminal mode: toggle terminal (snacks handles hiding when called from inside)
vim.keymap.set("t", [[<C-\>]], toggle_term, { silent = true, desc = "Toggle floating terminal" })
