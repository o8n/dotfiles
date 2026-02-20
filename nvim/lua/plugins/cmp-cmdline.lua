---@type LazySpec
return {
  "hrsh7th/nvim-cmp",
  keys = { ":", "/", "?" },
  dependencies = {
    "hrsh7th/cmp-cmdline",
  },
  config = function(plugin, opts)
    require "astronvim.plugins.configs.cmp"(plugin, opts)
    local cmp = require "cmp"

    -- `/` `?` 検索補完（バッファの単語から）
    cmp.setup.cmdline({ "/", "?" }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    -- `:` コマンドライン補完
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        {
          name = "cmdline",
          option = {
            ignore_cmds = { "Man", "!" },
          },
        },
      }),
    })
  end,
}
