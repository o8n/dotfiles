-- Language: Ruby
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = { "solargraph", "rubocop" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("lint").linters_by_ft = {
        ruby = { "rubocop" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
