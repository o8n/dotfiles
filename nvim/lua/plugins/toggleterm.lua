return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "ToggleTermToggleAll" },
  opts = {
    size = 15,
    persist_size = true,
    persist_mode = true,
  },
  keys = (function()
    local keys = {}
    for i = 1, 3 do
      table.insert(keys, {
        ("<Leader>t%d"):format(i),
        ("<Cmd>%dToggleTerm size=15 direction=horizontal<CR>"):format(i),
        desc = ("Terminal #%d"):format(i),
        mode = { "n", "t" },
      })
    end
    table.insert(keys, { "<Leader>tA", "<Cmd>ToggleTermToggleAll<CR>", desc = "Toggle all terminals" })
    table.insert(keys, { "<Leader>th", "<Cmd>ToggleTerm size=15 direction=horizontal<CR>", desc = "Horizontal terminal" })
    table.insert(keys, { "<Esc><Esc>", "<C-\\><C-n>", mode = "t", desc = "Exit terminal mode" })
    return keys
  end)(),
}
