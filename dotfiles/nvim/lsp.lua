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

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Elixir
-- Every Elixir devenv needs to have this envar defined
local elixir_ls_path = os.getenv("ELIXIR_LS_PATH")
lspconfig.elixirls.setup {
    cmd = { elixir_ls_path },
    filetypes = { "elixir", "eelixir", "heex", "surface" },
    capabilities = capabilities,
    -- root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
}

-- Erlang
require 'lspconfig'.erlangls.setup {
    capabilities = capabilities,
}

-- F#
require("ionide").setup {
    autostart = true,
    --on_attach = on_attach,
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
    --cmd = { "gleam", "lsp" },
    --filetypes = { "gleam" },
    --capabilities = capabilities
})

-- Nix
lspconfig.nil_ls.setup({
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
    cmd = { "ocamllsp" },
    filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex", "reason", "dune" },
    capabilities = capabilities
})

-- Terraform
require 'lspconfig'.terraformls.setup {}
vim.g.terraform_fmt_on_save = 1
vim.g.terraform_align = 1

-- Lua
require 'lspconfig'.lua_ls.setup {
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

-----------------------
-- Autocompletion setup
local cmp = require 'cmp'

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    formatting = {
        fields = { 'menu', 'abbr', 'kind' },
        format = function(entry, item)
            local menu_icon = {
                nvim_lsp = 'λ',
                luasnip = '⋗',
                buffer = 'Ω',
                path = '🖫',
            }

            item.menu = menu_icon[entry.source.name]
            return item
        end,
    },
    mapping = {
        ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
        ['<Down>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),

        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),

        ['<C-f>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(1) then
                luasnip.jump(1)
            else
                fallback()
            end
        end, { 'i', 's' }
        ),
        ['<C-b>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }
        ),
        ['<Tab>'] = cmp.mapping(function(fallback)
            local col = vim.fn.col('.') - 1

            if cmp.visible() then
                cmp.select_next_item(select_opts)
            elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                fallback()
            else
                cmp.complete()
            end
        end, { 'i', 's' }
        ),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item(select_opts)
            else
                fallback()
            end
        end, { 'i', 's' }
        ),
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'treesitter' }
    }, {
        { name = 'buffer' },
    })
}
)

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
        { name = 'buffer' },
    })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
}
)


-- Keybindings
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function()
        local bufmap = function(mode, lhs, rhs)
            local opts = { buffer = true }
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- Displays hover information about the symbol under the cursor
        bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')

        -- Jump to the definition
        bufmap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')

        -- Jump to declaration
        bufmap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')

        -- Lists all the implementations for the symbol under the cursor
        bufmap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')

        -- Jumps to the definition of the type symbol
        bufmap('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>')

        -- Lists all the references
        bufmap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>')

        -- Displays a function's signature information
        bufmap('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>')

        -- Renames all references to the symbol under the cursor
        bufmap('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>')

        -- Selects a code action available at the current cursor position
        bufmap('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>')

        -- Show diagnostics in a floating window
        bufmap('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')

        -- Move to the previous diagnostic
        bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

        -- Move to the next diagnostic
        bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
    end
})
