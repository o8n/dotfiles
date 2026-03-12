-- Options: vim.opt, vim.g settings
-- Must be loaded before lazy.nvim

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Editor options
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.spell = false
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.showmode = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.shortmess:append("c")
vim.opt.fillchars = { eob = " " }

-- Folding (for nvim-ufo)
vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Diagnostics
vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  signs = true,
  update_in_insert = false,
  severity_sort = true,
})
