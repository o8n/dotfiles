-- Ruby: RuboCop をフォーマッター/リンターとして使用
---@type LazySpec
return {
  -- RuboCop を Mason でインストール
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "rubocop",
      })
    end,
  },
  -- フォーマッターを RuboCop に設定
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" },
      },
    },
  },
  -- リンターを RuboCop に設定
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        ruby = { "rubocop" },
      },
    },
  },
}
