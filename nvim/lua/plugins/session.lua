-- Session management: resession.nvim
return {
  "stevearc/resession.nvim",
  lazy = false,
  opts = {},
  config = function(_, opts)
    local resession = require("resession")
    resession.setup(opts)

    -- Auto-save session on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if vim.fn.expand("%") ~= "" then
          resession.save(vim.fn.getcwd(), { dir = "dirsession", notify = false })
        end
      end,
    })

    -- Auto-restore session on start (only if no args)
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argc(-1) == 0 then
          pcall(resession.load, vim.fn.getcwd(), { dir = "dirsession", silence_errors = true })
        end
      end,
    })
  end,
}
