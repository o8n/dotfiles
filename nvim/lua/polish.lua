-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- 外部変更の自動リロード: フォーカス復帰やバッファ切替時にchecktimeを実行
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  pattern = "*",
  command = "checktime",
})

-- 自動保存: InsertLeave/FocusLostで保存（TextChangedは除外: normalモード操作ごとにwriteが走りleader key等の反応を阻害するため）
vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})
