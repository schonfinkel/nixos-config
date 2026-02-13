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
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- On Attach customizations
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer.
local on_attach = function(client, bufnr)
    if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable()
    end

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = true, buffer = bufnr }

    vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

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
    vim.keymap.set("n", "ca", vim.lsp.buf.code_action, bufopts)

    -- Show diagnostics in a floating window
    vim.keymap.set("n", "df", vim.diagnostic.open_float, bufopts)

    -- Run conform as the code's formatter
    vim.keymap.set("n", "<space>cf", function()
        -- vim.lsp.buf.formatting
        require("conform").format({ async = true, lsp_fallback = true })
    end, bufopts)

    -- GOTOs
    vim.keymap.set("n", "<space>gp", "vim.lsp.diagnostic.goto_prev", bufopts)
    vim.keymap.set("n", "<space>gn", "vim.lsp.diagnostic.goto_next", bufopts)

    -- Workspace Commands
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set("n", "<space>wl", vim.lsp.buf.list_workspace_folders, bufopts)
end

-- Code Formatters
local erlfmt = {
    meta = {
        url = "https://github.com/WhatsApp/erlfmt",
        description = "An opinionated Erlang code formatter.",
    },
    command = "erlfmt",
    args = { "-" },
    stdin = true,
}
require("conform").setup({
    formatters_by_ft = {
        erlang = { "erlfmt" },
        elixir = { "elixir-ls" },
        ocaml = { "ocamlformat" },
        rust = { "rustfmt" },
        zig = { "zigfmt" },
    },
    formatters = {
        erlfmt = erlfmt,
    },
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function(args)
        require("conform").format({ bufnr = args.buf })
    end,
})

-- Bash
vim.lsp.config["bashls"] = {
    on_attach = on_attach,
    capabilities = capabilities,
}
vim.lsp.enable("bashls")

-- Elixir
-- Every Elixir devenv needs to have this envar defined
local elixir_ls_path = os.getenv("ELIXIR_LS_PATH")
vim.lsp.config["elixirls"] = {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { elixir_ls_path },
    -- filetypes = { "ex", "elixir", "eelixir", "heex", "surface" },
    -- root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
}
vim.lsp.enable("elixirls")

-- Erlang
vim.lsp.config["elp"] = {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        elp = {
            diagnostics = {
                disabled = {
                    "W0030",
                    "W0031",
                    "W0032"
                }
            }
        }
    }
}

vim.lsp.enable("elp")

-- F#
require("ionide").setup({
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
	    FSharp = {
            enableMSBuildProjectGraph = true,
            inlayHints = {
                enabled = true,
                typeAnnotations = false,
                disableLongTooltip = false,
                parameterNames = false,
            },
			Linter = true,
		},
        IonideNvimSettings = {
            ShowSignatureOnCursorMove = false,
            FsiStdOutFileName = "./FsiOutput.txt",
            FsautocompleteCommand = { "fsautocomplete", "--project-graph-enabled", "--adaptive-lsp-server-enabled", "--use-fcs-transparent-compiler" },
            UseRecommendedServerConfig = false,
            AutomaticWorkspaceInit = false,
            AutomaticReloadWorkspace = false,
            AutomaticCodeLensRefresh = false,
            FsiCommand = "dotnet fsi",
            -- FsiKeymap = "vscode",
            FsiWindowCommand = "botright 10new",
            FsiFocusOnSend = false,
            EnableFsiStdOutTeeToFile = false,
            LspAutoSetup = false,
            LspRecommendedColorScheme = false,
            FsiVscodeKeymaps = true,
            StatusLine = "Ionide",
            FsiKeymapSend = "<M-cr>",
            FsiKeymapToggle = "<M-@>",
        },
    },
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.fs,*.fsx,*.fsi",
	command = [[set filetype=fsharp]],
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.fsproj,*.csproj,*.vbproj,*.cproj,*.proj",
	command = [[set filetype=xml]],
})

-- https://github.com/ionide/Ionide-vim?tab=readme-ov-file#settings
-- vim.api.nvim_command('autocmd BufNewFile,BufRead *.fs,*.fsx,*.fsi,*.fsl,*.fsy set filetype=fsharp')
-- vim.g["fsharp#lsp_auto_setup"] = 1
-- vim.g["fsharp#lsp_recommended_colorscheme"] = 1
-- vim.g["fsharp#automatic_workspace_init"] = 1
-- vim.g["fsharp#linter"] = 1
-- vim.g["fsharp#unused_opens_analyzer"] = 1
-- vim.g["fsharp#unused_declarations_analyzer"] = 1
-- vim.g["fsharp#show_signature_on_cursor_move"] = 1
-- vim.g["fsharp#fsi_focus_on_send"] = 1
-- vim.g["fsharp#fsautocomplete_command"] = { fs_autocomplete_path }

-- Gleam
vim.lsp.config["gleam"] = {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "gleam", "lsp" },
}
vim.lsp.enable("gleam")

-- Lua
vim.lsp.config["lua_ls"] = {
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
vim.lsp.enable("lua_ls")

-- Nix
vim.lsp.config["nil"] = {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        ['nil'] = {
            formatting = {
                command = { "nix fmt" },
            },
        },
    },
}
vim.lsp.enable("nil")

-- Ocaml
vim.lsp.config["ocamlsp"] = {
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
}
vim.lsp.enable("ocamlsp")

-- Terraform
vim.lsp.config["terraformls"] = {
    on_attach = on_attach,
    capabilities = capabilities
}
vim.lsp.enable("terraformls")

vim.g.terraform_fmt_on_save = 1
vim.g.terraform_align = 1

-- DBee Setup
local dbee = require('dbee')
dbee.setup()

vim.keymap.set({"n", "v"}, "<leader>do", function() dbee.open() end, { desc = "Open dbee UI" })
vim.keymap.set({"n", "v"}, "<leader>dc", function() dbee.close() end, { desc = "Close dbee UI" })
