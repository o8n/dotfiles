-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- 自動保存: テキスト変更時やフォーカスを失った時に即座に保存
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "FocusLost" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

-- Set up custom filetypes
-- vim.filetype.add {
  -- extension = {
    -- foo = "fooscript",
  -- },
  -- filename = {
    -- ["Foofile"] = "fooscript",
  -- },
  -- pattern = {
    -- ["~/%.config/foo/.*"] = "fooscript",
  -- },
-- }
