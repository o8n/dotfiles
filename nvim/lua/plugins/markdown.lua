-- Markdown tools: preview, glow, markview
return {
  -- Browser-based preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = "markdown",
    build = "cd app && npm install",
    keys = {
      { "<Leader>mp", "<Cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview" },
    },
  },
  -- Terminal-based preview
  {
    "ellisonleao/glow.nvim",
    cmd = "Glow",
    ft = "markdown",
    config = function()
      require("glow").setup({
        border = "rounded",
        style = "dark",
        pager = false,
        width = 120,
        height_ratio = 0.8,
      })
    end,
  },
  -- Inline preview in buffer
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
