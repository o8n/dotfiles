---@type LazySpec
return {
  "nvim-telescope/telescope.nvim",
  opts = function(_, opts)
    local ignore_patterns = {
      -- Version control
      "^%.git[/\\]",
      "[/\\]%.git[/\\]",
      -- Dependencies
      "[/\\]node_modules[/\\]",
      "[/\\]vendor[/\\]",
      -- Build artifacts
      "[/\\]dist[/\\]",
      "[/\\]build[/\\]",
      -- Python
      "[/\\]%.venv[/\\]",
      "[/\\]__pycache__[/\\]",
      "%.pyc$",
      -- Cache
      "[/\\]%.cache[/\\]",
    }

    opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
      file_ignore_patterns = ignore_patterns,
    })

    opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
      find_files = {
        hidden = true,
      },
      live_grep = {
        additional_args = { "--hidden" },
      },
    })
  end,
}
