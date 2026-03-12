-- Statusline: lualine.nvim (replaces heirline)

-- Worktree info cache (shared with gwq-ghq.lua via global)
_G._gwq_worktree_cache = _G._gwq_worktree_cache or {
  branch = nil,
  is_worktree = false,
}

-- Activity monitor stats cache (shared with activity-monitor.lua via global)
_G._activity_stats_cache = _G._activity_stats_cache or {
  cpu_total = 0,
  mem_percent = 0,
  top_process = "",
  updated_at = 0,
}

local function worktree_indicator()
  if _G._gwq_worktree_cache.is_worktree then
    return " wt"
  end
  return ""
end

local function activity_monitor()
  local stats = _G._activity_stats_cache
  if stats.updated_at <= 0 then return "" end
  return string.format("CPU:%.0f%% Mem:%.0f%%", stats.cpu_total, stats.mem_percent)
end

local function activity_monitor_color()
  local stats = _G._activity_stats_cache
  if stats.mem_percent > 80 or stats.cpu_total > 200 then
    return { fg = "#ed8796" }
  elseif stats.mem_percent > 60 or stats.cpu_total > 100 then
    return { fg = "#f5a97f" }
  end
  return { fg = "#a6da95" }
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      theme = "tokyonight",
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = {
        "branch",
        { worktree_indicator, color = { fg = "#f5a97f", gui = "bold" } },
        "diff",
        "diagnostics",
      },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = {
        { activity_monitor, color = activity_monitor_color },
        "encoding",
        "fileformat",
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
