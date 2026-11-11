-- gitsigns: sign column + line blame
local gitsigns = require("gitsigns")
gitsigns.setup({
    signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
    },
    current_line_blame = true,
    current_line_blame_opts = {
        delay = 300,
    },
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation through hunks
        map("n", "]h", function()
            if vim.wo.diff then return "]h" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
        end, { expr = true, desc = "Next git hunk" })

        map("n", "[h", function()
            if vim.wo.diff then return "[h" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
        end, { expr = true, desc = "Previous git hunk" })

        -- Actions
        map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
        map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line (full)" })
    end,
})

-- diffview: advanced diffs & 3-way merge tool
require("diffview").setup({
    enhanced_diff_hl = true,
    use_icons = true,
    view = {
        merge_tool = {
            layout = "diff3_mixed",
            disable_diagnostics = true,
        },
    },
})

vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open Diffview" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File History (Current)" })
vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Project File History" })

-- neogit: interactive git client with diffview integration
require("neogit").setup({
    kind = "tab",
    integrations = {
        diffview = true,
        telescope = true,
    },
})

vim.keymap.set("n", "<leader>gs", "<cmd>Neogit<cr>", { desc = "Open Neogit Status" })
vim.keymap.set("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Neogit Commit" })
