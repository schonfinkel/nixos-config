require('blink.cmp').setup({
    keymap = {
        preset = 'super-tab',
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-y>'] = { 'select_and_accept' },
        ['<C-e>'] = { 'cancel', 'fallback' },
        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-b>'] = { 'snippet_backward', 'fallback' },
        ['<C-f>'] = { 'snippet_forward', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
    },
    appearance = {
        nerd_font_variant = 'mono',
    },
    sources = {
        default = { 'lsp', 'snippets', 'path', 'buffer' },
        per_filetype = {
            -- For prose where LSP doesn't apply, buffer completions are useful
            markdown  = { 'buffer', 'path' },
            gitcommit = { 'buffer', 'path' },
            gleam = { 'lsp', 'snippets', 'path' },
            erlang = { 'lsp', 'snippets', 'path' },
            elixir = { inherit_defaults = true, 'hex' },
            -- sh benefits from buffer for variable names alongside LSP
            sh = { inherit_defaults = true, 'buffer' },
        },
    },
    completion = {
        list = {
            cycle = { from_bottom = true, from_top = true },
            selection = {
                preselect = true,
                -- Ghost text is preferable
                auto_insert = false,
            },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
        },
        ghost_text = { enabled = true },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    signature = { enabled = true },
})
