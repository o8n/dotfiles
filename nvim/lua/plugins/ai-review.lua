return {
  dir = vim.fn.expand("~/ghq/github.com/o8n/ai-review.nvim"),
  cmd = "AIReview",
  opts = {
    review_script = vim.fn.expand("~/.dotfiles/hooks/lib/dual-review.sh"),
    notify = true,
  },
  keys = {
    { "<Leader>ar", "<Cmd>AIReview<CR>", desc = "AI Review (staged)" },
    { "<Leader>aR", "<Cmd>AIReview --push<CR>", desc = "AI Review (push)" },
  },
}
