-- activity-monitor.lua -- System activity monitor with Telescope picker
-- Shows CPU/memory per process, recommends and kills heavy processes

---@class ProcessInfo
---@field pid number
---@field user string
---@field cpu number
---@field mem number
---@field rss number
---@field comm string
---@field full_cmd string
---@field is_killable boolean
---@field recommendation string|nil

---@class SystemStats
---@field total_mem_gb number
---@field used_mem_gb number
---@field free_mem_gb number
---@field mem_percent number

local PAGE_SIZE = 16384
local TOTAL_MEM = 38654705664 -- fallback, updated dynamically via sysctl

-- System-critical processes that should never be killed
local PROTECTED = {
  ["kernel_task"] = true,
  ["launchd"] = true,
  ["WindowServer"] = true,
  ["loginwindow"] = true,
  ["mds"] = true,
  ["mds_stores"] = true,
  ["notifyd"] = true,
  ["fseventsd"] = true,
  ["opendirectoryd"] = true,
  ["logd"] = true,
  ["configd"] = true,
  ["powerd"] = true,
  ["keybagd"] = true,
  ["watchdogd"] = true,
  ["systemstats"] = true,
}

-- Known resource-heavy application patterns
local KNOWN_HEAVY = {
  "Electron",
  "Slack",
  "Discord",
  "Spotify",
  "Teams",
  "Code Helper",
  "Figma Helper",
  "Notion Helper",
  "Google Chrome Helper",
}

-- ── Data Collection ──────────────────────────────────────────────

---Fetch total physical memory via sysctl (async, one-shot)
---@param callback fun(bytes: number)
local function fetch_total_memory(callback)
  vim.system({ "sysctl", "-n", "hw.memsize" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local bytes = tonumber(vim.trim(result.stdout))
        if bytes then callback(bytes) end
      end
    end)
  end)
end

---Parse vm_stat output into SystemStats
---@param callback fun(stats: SystemStats)
local function fetch_vm_stat(callback)
  vim.system({ "vm_stat" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then return end
      local text = result.stdout
      local function extract(pattern)
        local val = text:match(pattern)
        if val then return tonumber((val:gsub("%.", ""))) or 0 end
        return 0
      end
      local free = extract "Pages free:%s+(%d+%.)"
      local active = extract "Pages active:%s+(%d+%.)"
      local wired = extract "Pages wired down:%s+(%d+%.)"

      local used_bytes = (active + wired) * PAGE_SIZE
      callback {
        total_mem_gb = TOTAL_MEM / (1024 ^ 3),
        used_mem_gb = used_bytes / (1024 ^ 3),
        free_mem_gb = (TOTAL_MEM - used_bytes) / (1024 ^ 3),
        mem_percent = (used_bytes / TOTAL_MEM) * 100,
      }
    end)
  end)
end

---Compute recommendation string for a process
---@param p ProcessInfo
---@return string|nil
local function compute_recommendation(p)
  if PROTECTED[p.comm] then return nil end

  local reasons = {}
  if p.cpu > 50 then table.insert(reasons, "High CPU (" .. string.format("%.0f%%", p.cpu) .. ")") end
  if p.mem > 5 then table.insert(reasons, "High Memory (" .. string.format("%.1f%%", p.mem) .. ")") end

  for _, pattern in ipairs(KNOWN_HEAVY) do
    if p.full_cmd:find(pattern, 1, true) then
      table.insert(reasons, "Electron/heavy app")
      break
    end
  end

  if #reasons > 0 then return table.concat(reasons, ", ") end
  return nil
end

---Format RSS in human-readable form
---@param rss_kb number
---@return string
local function format_rss(rss_kb)
  if rss_kb >= 1048576 then
    return string.format("%.1fG", rss_kb / 1048576)
  elseif rss_kb >= 1024 then
    return string.format("%.0fM", rss_kb / 1024)
  else
    return string.format("%dK", rss_kb)
  end
end

---Fetch process list parsed into ProcessInfo[]
---@param callback fun(processes: ProcessInfo[])
local function fetch_processes(callback)
  vim.system({ "ps", "-eo", "pid,pcpu,pmem,rss,user,comm" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("activity-monitor: ps failed", vim.log.levels.ERROR)
        return
      end
      local lines = vim.split(result.stdout, "\n", { trimempty = true })
      local processes = {}
      for i = 2, #lines do
        local pid, cpu, mem, rss, user, comm =
          lines[i]:match "^%s*(%d+)%s+([%d.]+)%s+([%d.]+)%s+(%d+)%s+(%S+)%s+(.+)$"
        if pid then
          local p = {
            pid = tonumber(pid),
            cpu = tonumber(cpu) or 0,
            mem = tonumber(mem) or 0,
            rss = tonumber(rss) or 0,
            user = user,
            comm = vim.fn.fnamemodify(vim.trim(comm), ":t"),
            full_cmd = vim.trim(comm),
            is_killable = (user == os.getenv "USER"),
            recommendation = nil,
          }
          p.recommendation = compute_recommendation(p)
          table.insert(processes, p)
        end
      end
      table.sort(processes, function(a, b) return a.cpu > b.cpu end)
      callback(processes)
    end)
  end)
end

-- ── Kill Action ──────────────────────────────────────────────────

---Kill a process selected in the Telescope picker
---@param prompt_bufnr number
---@param signal number
---@param reopen_fn fun()
local function kill_process(prompt_bufnr, signal, reopen_fn)
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"

  local selection = action_state.get_selected_entry()
  if not selection then return end
  local p = selection.value

  if PROTECTED[p.comm] then
    vim.notify("Cannot kill protected process: " .. p.comm, vim.log.levels.ERROR)
    return
  end
  if not p.is_killable then
    vim.notify("Cannot kill process owned by " .. p.user, vim.log.levels.WARN)
    return
  end

  local signal_name = signal == 9 and "SIGKILL" or "SIGTERM"
  vim.ui.input({
    prompt = string.format("Send %s to %s (PID %d)? (y/N): ", signal_name, p.comm, p.pid),
  }, function(input)
    if input and input:lower() == "y" then
      vim.system({ "kill", "-" .. signal, tostring(p.pid) }, { text = true }, function(result)
        vim.schedule(function()
          if result.code == 0 then
            vim.notify(string.format("Killed %s (PID %d)", p.comm, p.pid))
            actions.close(prompt_bufnr)
            vim.defer_fn(reopen_fn, 500)
          else
            vim.notify("Kill failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
          end
        end)
      end)
    end
  end)
end

-- ── Telescope Pickers ────────────────────────────────────────────

-- Forward declaration for cross-reference
local flagged_picker

---Open Telescope picker showing system processes
---@param opts? table
---@param sort_by? "cpu"|"mem"
local function process_picker(opts, sort_by)
  opts = opts or {}
  sort_by = sort_by or "cpu"

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"
  local previewers = require "telescope.previewers"

  fetch_processes(function(processes)
    if not processes or #processes == 0 then
      vim.notify("No processes found", vim.log.levels.WARN)
      return
    end

    if sort_by == "mem" then
      table.sort(processes, function(a, b) return a.mem > b.mem end)
    end

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 2 },
        { width = 7 },
        { width = 7 },
        { width = 7 },
        { width = 10 },
        { width = 12 },
        { remaining = true },
      },
    }

    pickers
      .new(opts, {
        prompt_title = "Activity Monitor (sort: " .. sort_by .. ")",
        finder = finders.new_table {
          results = processes,
          entry_maker = function(proc)
            return {
              value = proc,
              display = function(entry)
                local p = entry.value
                local indicator = p.recommendation and "*" or " "
                local cpu_hl = p.cpu > 50 and "DiagnosticError"
                  or p.cpu > 20 and "DiagnosticWarn"
                  or "TelescopeResultsNumber"
                local mem_hl = p.mem > 5 and "DiagnosticError"
                  or p.mem > 2 and "DiagnosticWarn"
                  or "TelescopeResultsNumber"
                return displayer {
                  { indicator, p.recommendation and "DiagnosticWarn" or "Normal" },
                  { tostring(p.pid), "TelescopeResultsComment" },
                  { string.format("%.1f%%", p.cpu), cpu_hl },
                  { string.format("%.1f%%", p.mem), mem_hl },
                  { format_rss(p.rss), "TelescopeResultsNumber" },
                  { p.user, "TelescopeResultsComment" },
                  { p.comm, "TelescopeResultsIdentifier" },
                }
              end,
              ordinal = proc.comm .. " " .. tostring(proc.pid) .. " " .. proc.user,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer {
          title = "Process Details",
          define_preview = function(self, entry)
            local p = entry.value
            local lines = {
              "PID:         " .. p.pid,
              "User:        " .. p.user,
              "CPU:         " .. string.format("%.1f%%", p.cpu),
              "Memory:      " .. string.format("%.1f%% (%s)", p.mem, format_rss(p.rss)),
              "Command:     " .. p.full_cmd,
              "",
              "Killable:    " .. (p.is_killable and "Yes" or "No (different user)"),
            }
            if p.recommendation then
              table.insert(lines, "")
              table.insert(lines, "--- Recommendation ---")
              table.insert(lines, p.recommendation)
            end
            if PROTECTED[p.comm] then
              table.insert(lines, "")
              table.insert(lines, "*** PROTECTED: System-critical process ***")
            end
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        },
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            if not selection then return end
            actions.close(prompt_bufnr)
            local p = selection.value
            vim.notify(
              string.format(
                "PID %d (%s): CPU %.1f%%, Mem %.1f%% (%s)\n%s",
                p.pid,
                p.comm,
                p.cpu,
                p.mem,
                format_rss(p.rss),
                p.recommendation or "No issues detected"
              ),
              vim.log.levels.INFO
            )
          end)
          map("i", "<C-k>", function()
            kill_process(prompt_bufnr, 15, function() process_picker(opts, sort_by) end)
          end)
          map("n", "K", function()
            kill_process(prompt_bufnr, 15, function() process_picker(opts, sort_by) end)
          end)
          map("i", "<C-s>", function()
            actions.close(prompt_bufnr)
            process_picker(opts, sort_by == "cpu" and "mem" or "cpu")
          end)
          map("i", "<C-r>", function()
            actions.close(prompt_bufnr)
            process_picker(opts, sort_by)
          end)
          map("i", "<C-f>", function()
            actions.close(prompt_bufnr)
            flagged_picker(opts)
          end)
          return true
        end,
      })
      :find()
  end)
end

---Show only processes that have been flagged with recommendations
---@param opts? table
flagged_picker = function(opts)
  opts = opts or {}
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"
  local previewers = require "telescope.previewers"

  fetch_processes(function(processes)
    local flagged = vim.tbl_filter(function(p) return p.recommendation ~= nil end, processes)
    if #flagged == 0 then
      vim.notify("No resource-heavy processes detected", vim.log.levels.INFO)
      return
    end

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 7 },
        { width = 7 },
        { width = 7 },
        { width = 10 },
        { width = 20 },
        { remaining = true },
      },
    }

    pickers
      .new(opts, {
        prompt_title = "Flagged Processes (" .. #flagged .. " found)",
        finder = finders.new_table {
          results = flagged,
          entry_maker = function(proc)
            return {
              value = proc,
              display = function(entry)
                local p = entry.value
                return displayer {
                  { tostring(p.pid), "TelescopeResultsComment" },
                  { string.format("%.1f%%", p.cpu), "DiagnosticWarn" },
                  { string.format("%.1f%%", p.mem), "DiagnosticWarn" },
                  { format_rss(p.rss), "TelescopeResultsNumber" },
                  { p.comm, "TelescopeResultsIdentifier" },
                  { p.recommendation or "", "DiagnosticHint" },
                }
              end,
              ordinal = proc.comm .. " " .. tostring(proc.pid),
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer {
          title = "Process Details",
          define_preview = function(self, entry)
            local p = entry.value
            local lines = {
              "PID:            " .. p.pid,
              "User:           " .. p.user,
              "CPU:            " .. string.format("%.1f%%", p.cpu),
              "Memory:         " .. string.format("%.1f%% (%s)", p.mem, format_rss(p.rss)),
              "Command:        " .. p.full_cmd,
              "",
              "Killable:       " .. (p.is_killable and "Yes" or "No"),
              "",
              "Recommendation: " .. (p.recommendation or "None"),
            }
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          end,
        },
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            if not selection then return end
            actions.close(prompt_bufnr)
            local p = selection.value
            vim.notify(
              string.format("%s (PID %d): %s", p.comm, p.pid, p.recommendation or ""),
              vim.log.levels.INFO
            )
          end)
          map("i", "<C-k>", function()
            kill_process(prompt_bufnr, 15, function() flagged_picker(opts) end)
          end)
          map("n", "K", function()
            kill_process(prompt_bufnr, 15, function() flagged_picker(opts) end)
          end)
          map("i", "<C-a>", function()
            actions.close(prompt_bufnr)
            process_picker(opts)
          end)
          return true
        end,
      })
      :find()
  end)
end

-- ── System Summary ───────────────────────────────────────────────

---Show a system resource summary notification
local function show_system_summary()
  fetch_vm_stat(function(sys)
    fetch_processes(function(processes)
      local top5 = {}
      for i = 1, math.min(5, #processes) do
        local p = processes[i]
        table.insert(
          top5,
          string.format("  %s (PID %d): CPU %.1f%%, Mem %s", p.comm, p.pid, p.cpu, format_rss(p.rss))
        )
      end
      vim.notify(
        string.format(
          "Memory: %.1f / %.1f GB (%.0f%%)\n\nTop CPU consumers:\n%s",
          sys.used_mem_gb,
          sys.total_mem_gb,
          sys.mem_percent,
          table.concat(top5, "\n")
        ),
        vim.log.levels.INFO,
        { title = "System Activity" }
      )
    end)
  end)
end

-- ── Plugin Specs ─────────────────────────────────────────────────

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = function(_, opts)
      local maps = opts.mappings or {}

      maps.n["<Leader>a"] = { desc = "Activity Monitor" }
      maps.n["<Leader>aa"] = { function() process_picker() end, desc = "Process list (CPU)" }
      maps.n["<Leader>am"] = { function() process_picker({}, "mem") end, desc = "Process list (Memory)" }
      maps.n["<Leader>af"] = { function() flagged_picker() end, desc = "Flagged processes" }
      maps.n["<Leader>as"] = { function() show_system_summary() end, desc = "System summary" }

      opts.commands = opts.commands or {}
      opts.commands.ActivityMonitor = { function() process_picker() end, desc = "Open activity monitor" }
      opts.commands.ActivitySummary = {
        function() show_system_summary() end,
        desc = "Show system resource summary",
      }
      opts.commands.ActivityKill = {
        function(cmd)
          local pid = tonumber(cmd.args)
          if not pid then
            vim.notify("Usage: :ActivityKill <PID>", vim.log.levels.WARN)
            return
          end
          vim.ui.input({ prompt = "Kill PID " .. pid .. "? (y/N): " }, function(input)
            if input and input:lower() == "y" then
              vim.system({ "kill", "-15", tostring(pid) }, { text = true }, function(result)
                vim.schedule(function()
                  if result.code == 0 then
                    vim.notify("Killed PID " .. pid)
                  else
                    vim.notify("Failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
                  end
                end)
              end)
            end
          end)
        end,
        nargs = 1,
        desc = "Kill process by PID",
      }

      opts.autocmds = opts.autocmds or {}
      opts.autocmds.activity_monitor_refresh = {
        {
          event = "VimEnter",
          desc = "Initialize activity monitor total memory",
          callback = function()
            fetch_total_memory(function(bytes) TOTAL_MEM = bytes end)
          end,
        },
      }
    end,
  },

}
