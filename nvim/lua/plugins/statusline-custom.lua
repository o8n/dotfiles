-- statusline-custom.lua -- Custom statusline: relative file path + clock
-- Depends on load order: activity-monitor.lua (a) → gwq-ghq.lua (g) → this file (s)

local time_cache = { str = os.date("%H:%M") }
local time_timer = nil

local function start_time_refresh()
  if time_timer then return end
  time_timer = vim.uv.new_timer()
  time_timer:start(0, 60000, function()
    vim.schedule(function()
      time_cache.str = os.date("%H:%M")
      vim.cmd.redrawstatus()
    end)
  end)
end

local function stop_time_refresh()
  if time_timer then
    time_timer:stop()
    time_timer:close()
    time_timer = nil
  end
end

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.statusline_clock = {
        {
          event = "VimEnter",
          desc = "Start statusline clock refresh",
          callback = start_time_refresh,
        },
        {
          event = "VimLeavePre",
          desc = "Stop statusline clock refresh",
          callback = stop_time_refresh,
        },
      }
    end,
  },

  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      if not opts.statusline then return end
      local status = require "astroui.status"

      -- 1. Replace file_info with relative path version
      -- After activity-monitor.lua and gwq-ghq.lua, file_info is at index 4:
      --   [1] mode [2] git_branch [3] worktree [4] file_info ...
      opts.statusline[4] = status.component.file_info {
        filename = { modify = ":." },
        filetype = false,
      }

      -- 2. Insert clock before nav (currently at index 13)
      --   ... [12] treesitter [13] nav [14] activity_monitor [15] mode_right
      local clock_component = {
        provider = function() return "  " .. time_cache.str .. " " end,
        hl = { fg = "#8aadf4" },
      }
      table.insert(opts.statusline, 13, clock_component)
    end,
  },
}
