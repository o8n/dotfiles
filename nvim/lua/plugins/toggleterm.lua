---@type LazySpec
return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "ToggleTermToggleAll" },
  opts = {
    size = 15,
    persist_size = true,
    persist_mode = true,
    shade_terminals = true,
    shading_factor = -10,
    float_opts = {
      border = "rounded",
    },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings

        for i = 1, 3 do
          maps.n[("<Leader>t%d"):format(i)] = {
            ("<Cmd>%dToggleTerm size=15 direction=horizontal<CR>"):format(i),
            desc = ("Terminal #%d"):format(i),
          }
          maps.t[("<Leader>t%d"):format(i)] = {
            ("<Cmd>%dToggleTerm size=15 direction=horizontal<CR>"):format(i),
            desc = ("Terminal #%d"):format(i),
          }
        end

        maps.n["<Leader>tA"] = { "<Cmd>ToggleTermToggleAll<CR>", desc = "Toggle all terminals" }
        maps.n["<Leader>th"] = { "<Cmd>ToggleTerm size=15 direction=horizontal<CR>", desc = "Horizontal terminal" }
        maps.n["<Leader>tf"] = { "<Cmd>ToggleTerm direction=float<CR>", desc = "Float terminal" }
        maps.t["<Esc><Esc>"] = { "<C-\\><C-n>", desc = "Exit terminal mode" }
      end,
    },
  },
}
