-- UI: which-key, dressing, alpha, notify, colorizer, smart-splits, presence
return {
  -- Keymap hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<Leader>b", group = "Buffers" },
        { "<Leader>f", group = "Find" },
        { "<Leader>g", group = "Git" },
        { "<Leader>gw", group = "Worktrees" },
        { "<Leader>gx", group = "Git Conflict" },
        { "<Leader>l", group = "LSP" },
        { "<Leader>t", group = "Terminal" },
        { "<Leader>a", group = "Activity Monitor" },
        { "<Leader>m", group = "Markdown" },
      })
    end,
  },
  -- Better UI for vim.ui.select/input
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },
  -- Dashboard
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {}
      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file", "<Cmd>Telescope find_files<CR>"),
        dashboard.button("r", "  Recent files", "<Cmd>Telescope oldfiles<CR>"),
        dashboard.button("g", "  Find text", "<Cmd>Telescope live_grep<CR>"),
        dashboard.button("e", "  New file", "<Cmd>ene<CR>"),
        dashboard.button("q", "  Quit", "<Cmd>qa<CR>"),
      }
      alpha.setup(dashboard.opts)
    end,
  },
  -- Notifications
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      vim.notify = require("notify")
    end,
  },
  -- Color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
  -- Smart window splits
  {
    "mrjones2014/smart-splits.nvim",
    event = "VeryLazy",
    opts = {},
  },
  -- Discord presence
  { "andweeb/presence.nvim", event = "VeryLazy" },
}
