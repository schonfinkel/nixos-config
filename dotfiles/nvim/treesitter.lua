-- Fallback for the absolute latest version if configs.setup is dead
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local bufnr = args.buf
    local ft = vim.bo[bufnr].filetype
    
    -- To exclude certain parses, just to this
    -- if ft == "just" then return end

    -- Start highlighting if a parser exists
    local lang = vim.treesitter.language.get_lang(ft)
    if lang then
      pcall(vim.treesitter.start, bufnr, lang)
    end
  end,
})

-- Enable Treesitter-based folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- Don't fold by default when opening
vim.opt.foldenable = false
