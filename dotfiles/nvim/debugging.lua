--------------------
-- Debug Adapter ---

-- NOTE: this file must never be named dap.lua or debug.lua: config files
-- under ~/.config/nvim precede plugins in runtimepath, and `require("dap")`
-- would shadow nvim-dap's own module; `require("debug")` resolves to Lua's
-- stdlib debug library via package.loaded and never loads a file at all.

local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

-- Open/close dap-ui automatically when a debug session starts/ends
dap.listeners.before.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- LLDB debug adapter (shipped by the lldb package as lldb-dap)
dap.adapters.lldb = {
    type = "executable",
    command = vim.fn.exepath("lldb-dap"),
}

-- Odin: build with `odin build . -debug` first. The executable location is
-- prompted for (defaulting to the project root).
--
-- custom program path, args, or `preRunCommands` loading an
-- odin_lldb.py formatter script -- belong in the project's .nvim.lua
-- (enabled by vim.opt.exrc in settings.lua).
dap.configurations.odin = {
    {
        type = "lldb",
        request = "launch",
        name = "Odin Debug",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        args = {},
        stopOnEntry = false,
    },
}

-- Keymaps
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", dap.set_breakpoint, { desc = "DAP set breakpoint" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "DAP terminate" })
vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "DAP pause" })

vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })
vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "DAP UI eval" })
