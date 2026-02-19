-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are some examples:

---@type LazySpec
return {

  -- == Examples of Adding Plugins ==

  "andweeb/presence.nvim",
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },

  -- == Examples of Overriding Plugins ==

  -- customize alpha options
  {
    "goolord/alpha-nvim",
    opts = function(_, opts)
      -- customize the dashboard header
      opts.section.header.val = {
      }
      return opts
    end,
  },

  -- You can disable default plugins as follows:
  { "max397574/better-escape.nvim", enabled = false },

  -- Markdown preview with glow.nvim (renders in terminal buffer)
  {
    "ellisonleao/glow.nvim",
    cmd = "Glow",
    ft = "markdown",
    config = function()
      require("glow").setup({
        border = "rounded",       -- floating window border
        style = "dark",           -- 'dark' or 'light'
        pager = false,            -- use pager for long content
        width = 120,              -- max width of window
        height_ratio = 0.8,       -- height ratio of window
      })
    end,
  },

  -- Markdown inline preview (renders in same buffer)
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
    end,
  },

  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom autopairs configuration such as custom rules
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules(
        {
          Rule("$", "$", { "tex", "latex" })
            -- don't add a pair if the next character is %
            :with_pair(cond.not_after_regex "%%")
            -- don't add a pair if  the previous character is xxx
            :with_pair(
              cond.not_before_regex("xxx", 3)
            )
            -- don't move right when repeat character
            :with_move(cond.none())
            -- don't delete if the next character is xx
            :with_del(cond.not_after_regex "xx")
            -- disable adding a newline when you press <cr>
            :with_cr(cond.none()),
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end,
  },

  -- Neo-tree を左側に配置
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,          -- フィルタされたアイテムを薄く表示
          hide_dotfiles = false,   -- ドットファイル（.envなど）を表示
          hide_gitignored = false, -- gitignoreされたファイルを表示
        },
      },
      window = {
        position = "left",
        mappings = {
          -- Neo-tree内からTelescopeを呼び出す
          ["<Leader>ff"] = function()
            vim.cmd("wincmd l") -- 右のウィンドウに移動
            require("telescope.builtin").find_files()
          end,
        },
      },
    },
  },

  -- Telescope で隠しファイル・gitignoreファイルを検索可能に
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        file_ignore_patterns = {}, -- 無視パターンをクリア
      },
      pickers = {
        find_files = {
          hidden = true,           -- 隠しファイルを表示
          no_ignore = true,        -- .gitignoreを無視
        },
        live_grep = {
          additional_args = function()
            return { "--hidden", "--no-ignore" }
          end,
        },
      },
    },
  },

  -- GitLens的なgit blame表示
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true, -- 行末にblame情報を表示
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 行末に表示
        delay = 500, -- 500msの遅延後に表示
        ignore_whitespace = false,
      },
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
    },
  },
}
