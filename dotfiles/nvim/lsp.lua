-- Languages
vim.o.completeopt = "menu,menuone,noselect"

-----------------------
-- Language Servers ---

-- Set tab to accept the autocompletion
local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end
_G.tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return t "<C-n>"
    else
        return t "<S-Tab>"
    end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", { expr = true })
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", { expr = true })
vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename)

-- Setup
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- On Attach customizations
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer.
local on_attach = function(client, bufnr)
    -- Rust-specific configurations
    if client.name == "rust_analyzer" then
        -- WARNING: This feature requires Neovim v0.10+
        vim.lsp.inlay_hint.enable()
    end

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    -- Displays hover information about the symbol under the cursor
    vim.keymap.set({ "n", "v" }, "K", vim.lsp.buf.hover, bufopts)

    -- Jump to the definition
    vim.keymap.set({ "n", "v" }, "gd", vim.lsp.buf.definition, bufopts)

    -- Jump to declaration
    vim.keymap.set({ "n", "v" }, "gD", vim.lsp.buf.declaration, bufopts)

    -- Jumps to the definition of the type symbol
    vim.keymap.set({ "n", "v" }, "gt", vim.lsp.buf.type_definition, bufopts)

    -- Lists all the implementations for the symbol under the cursor
    vim.keymap.set({ "n", "v" }, "gi", vim.lsp.buf.implementation, bufopts)

    -- Displays a function's signature information
    vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, bufopts)

    -- Lists all the references
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)

    -- Selects a code action available at the current cursor position
    vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, bufopts)

    -- Show diagnostics in a floating window
    vim.keymap.set("n", "df", vim.diagnostic.open_float, bufopts)

    -- Run conform as the code's formatter
    vim.keymap.set("n", "<space>cf", function()
        require("conform").format({ async = true, lsp_fallback = true })
    end, bufopts)
end

-- Code Formatter
require("conform").setup({
    formatters_by_ft = {
        erlang = { "erlfmt " },
        elixir = { "elixir-ls" },
        ocaml = { "ocamlformat" },
        rust = { "rustfmt" },
    },
})

-- Elixir
-- Every Elixir devenv needs to have this envar defined
local elixir_ls_path = os.getenv("ELIXIR_LS_PATH")
lspconfig.elixirls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { elixir_ls_path },
    -- filetypes = { "ex", "elixir", "eelixir", "heex", "surface" },
    -- root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
}

-- Erlang
lspconfig.erlangls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

-- F#
require("ionide").setup {
    autostart = true,
    on_attach = on_attach,
    capabilities = capabilities,
}

-- https://github.com/ionide/Ionide-vim?tab=readme-ov-file#settings
vim.api.nvim_command('autocmd BufNewFile,BufRead *.fs,*.fsx,*.fsi,*.fsl,*.fsy set filetype=fsharp')
vim.api.nvim_command('autocmd BufNewFile,BufRead *.fsproj,*.csproj,*.vbproj,*.cproj,*.proj set filetype=xml')

vim.g["fsharp#lsp_auto_setup"] = 1
vim.g["fsharp#lsp_recommended_colorscheme"] = 1
vim.g["fsharp#automatic_workspace_init"] = 1
vim.g["fsharp#linter"] = 1
vim.g["fsharp#unused_opens_analyzer"] = 1
vim.g["fsharp#unused_declarations_analyzer"] = 1
vim.g["fsharp#show_signature_on_cursor_move"] = 1
vim.g["fsharp#fsi_focus_on_send"] = 1

-- Gleam
lspconfig.gleam.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "gleam", "lsp" },
    --filetypes = { "gleam" },
})

-- Nix
lspconfig.nil_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        ['nil'] = {
            formatting = {
                command = { "nixfmt" },
            },
        },
    },
})

-- Ocaml
lspconfig.ocamllsp.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "ocamllsp", "--fallback-read-dot-merlin" },
    filetypes = {
        "dune",
        "ml",
        "mli",
        "menhir",
        "ocaml",
        "ocaml.menhir",
        "ocaml.interface",
        "ocamlinterface",
        "ocaml.ocamllex",
        "reason"
    }
})

-- Lua
lspconfig.lua_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { 'vim' },
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },
        },
    },
}

-- Terraform
lspconfig.terraformls.setup {
    on_attach = on_attach,
    capabilities = capabilities
}
vim.g.terraform_fmt_on_save = 1
vim.g.terraform_align = 1
