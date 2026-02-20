---@type LazySpec
return {
  dir = vim.fn.expand("~/ghq/github.com/o8n/ai-review.nvim"),
  cmd = "AIReview",
  opts = {
    review_script = vim.fn.expand("~/.dotfiles/hooks/lib/dual-review.sh"),
    notify = true,
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        opts.mappings.n["<Leader>ar"] = {
          "<Cmd>AIReview<CR>",
          desc = "AI Review (staged)",
        }
        opts.mappings.n["<Leader>aR"] = {
          "<Cmd>AIReview --push<CR>",
          desc = "AI Review (push)",
        }
      end,
    },
  },
}
