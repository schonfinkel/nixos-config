-- We use an autocmd to start highlighting because the old 'setup' is gone.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    -- Check if we have a parser for this filetype
    local ft = vim.bo[bufnr].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    
    if lang then
      -- Attempt to start highlighting. Using pcall prevents 
      -- startup errors if a specific parser is missing.
      pcall(vim.treesitter.start, bufnr, lang)
    end
  end,
})

-- Indentation
vim.api.nvim_create_autocmd("FileType", {
  group = ts_group,
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    -- Check if nvim-treesitter has an indentation module for this language
    local has_indent = pcall(require, "nvim-treesitter.indent")
    
    if has_indent and vim.treesitter.language.get_lang(ft) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Folding logic
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
-- Start with all folds open
vim.opt.foldlevel = 99
-- Close all folds when opening a file
vim.opt.foldlevelstart = 1
vim.opt.foldnestmax = 4
vim.opt.foldenable = true
