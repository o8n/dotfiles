---@type LazySpec
return {
  "dmtrKovalenko/fff.nvim",
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  lazy = false,
  opts = {},
  keys = {
    {
      "<Leader>ff",
      function() require("fff").find_files() end,
      desc = "FFF find files",
    },
    {
      "<Leader>fw",
      function() require("fff").live_grep() end,
      desc = "FFF live grep",
    },
    {
      "<Leader>fz",
      function()
        require("fff").live_grep({
          grep = {
            modes = { "fuzzy", "plain" },
          },
        })
      end,
      desc = "FFF fuzzy grep",
    },
  },
}
