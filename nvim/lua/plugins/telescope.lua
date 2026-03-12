-- Telescope: fuzzy finder
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<Leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Find buffers" },
    { "<Leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Find help" },
    { "<Leader>fk", "<Cmd>Telescope keymaps<CR>", desc = "Find keymaps" },
    { "<Leader>fo", "<Cmd>Telescope oldfiles<CR>", desc = "Find recent files" },
    { "<Leader>fd", "<Cmd>Telescope diagnostics<CR>", desc = "Find diagnostics" },
    { "<Leader>fr", "<Cmd>Telescope resume<CR>", desc = "Resume search" },
  },
  opts = {
    defaults = {
      file_ignore_patterns = {
        "^%.git[/\\]",
        "[/\\]%.git[/\\]",
        "[/\\]node_modules[/\\]",
        "[/\\]vendor[/\\]",
        "[/\\]dist[/\\]",
        "[/\\]build[/\\]",
        "[/\\]%.venv[/\\]",
        "[/\\]__pycache__[/\\]",
        "%.pyc$",
        "[/\\]%.cache[/\\]",
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      live_grep = {
        additional_args = { "--hidden" },
      },
    },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
  end,
}
