---@type LazySpec
return {
  "akinsho/git-conflict.nvim",
  version = "*",
  event = "User AstroGitFile",
  opts = {
    default_mappings = true,
    default_commands = true,
    disable_diagnostics = false,
    highlights = {
      incoming = "DiffAdd",
      current = "DiffText",
    },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>gx"] = { desc = "Git Conflict" }
        maps.n["<Leader>gxo"] = { "<Cmd>GitConflictChooseOurs<CR>", desc = "Choose current (ours)" }
        maps.n["<Leader>gxt"] = { "<Cmd>GitConflictChooseTheirs<CR>", desc = "Choose incoming (theirs)" }
        maps.n["<Leader>gxb"] = { "<Cmd>GitConflictChooseBoth<CR>", desc = "Choose both" }
        maps.n["<Leader>gx0"] = { "<Cmd>GitConflictChooseNone<CR>", desc = "Choose none" }
        maps.n["<Leader>gxn"] = { "<Cmd>GitConflictNextConflict<CR>", desc = "Next conflict" }
        maps.n["<Leader>gxp"] = { "<Cmd>GitConflictPrevConflict<CR>", desc = "Previous conflict" }
        maps.n["<Leader>gxq"] = { "<Cmd>GitConflictListQf<CR>", desc = "List conflicts (quickfix)" }
      end,
    },
  },
}
