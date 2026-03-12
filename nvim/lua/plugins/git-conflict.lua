return {
  "akinsho/git-conflict.nvim",
  version = "*",
  event = "VeryLazy",
  opts = {
    default_mappings = true,
    default_commands = true,
    disable_diagnostics = false,
    highlights = {
      incoming = "DiffAdd",
      current = "DiffText",
    },
  },
  keys = {
    { "<Leader>gx", "", desc = "Git Conflict" },
    { "<Leader>gxo", "<Cmd>GitConflictChooseOurs<CR>", desc = "Choose current (ours)" },
    { "<Leader>gxt", "<Cmd>GitConflictChooseTheirs<CR>", desc = "Choose incoming (theirs)" },
    { "<Leader>gxb", "<Cmd>GitConflictChooseBoth<CR>", desc = "Choose both" },
    { "<Leader>gx0", "<Cmd>GitConflictChooseNone<CR>", desc = "Choose none" },
    { "<Leader>gxn", "<Cmd>GitConflictNextConflict<CR>", desc = "Next conflict" },
    { "<Leader>gxp", "<Cmd>GitConflictPrevConflict<CR>", desc = "Previous conflict" },
    { "<Leader>gxq", "<Cmd>GitConflictListQf<CR>", desc = "List conflicts (quickfix)" },
  },
}
