-- gwq (Git Worktree Manager) + ghq integration for AstroNvim v4
-- Provides Telescope pickers, commands, session integration, and statusline indicator

local gwq_bin = vim.fn.expand "$HOME/go/bin/gwq"
local ghq_bin = "/opt/homebrew/bin/ghq"

-- Worktree info cache for statusline (module-level)
local worktree_cache = {
  branch = nil,
  is_worktree = false,
}

---Run a shell command asynchronously and return parsed JSON via callback
---@param cmd string
---@param args string[]
---@param callback fun(data: any)
local function run_cmd_json(cmd, args, callback)
  vim.system(vim.list_extend({ cmd }, args), { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("gwq: " .. (result.stderr or "command failed"), vim.log.levels.ERROR)
        return
      end
      local ok, data = pcall(vim.json.decode, result.stdout)
      if ok then
        callback(data)
      else
        vim.notify("gwq: JSON parse error", vim.log.levels.ERROR)
      end
    end)
  end)
end

---Run a shell command asynchronously and return stdout lines via callback
---@param cmd string
---@param args string[]
---@param callback fun(lines: string[])
local function run_cmd_lines(cmd, args, callback)
  vim.system(vim.list_extend({ cmd }, args), { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("command failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      local lines = vim.split(result.stdout, "\n", { trimempty = true })
      callback(lines)
    end)
  end)
end

---Save current session, switch directory, and restore target session
---@param target_path string
local function switch_to_directory(target_path)
  local cwd = vim.fn.getcwd()
  if cwd == target_path then
    vim.notify("Already in this directory", vim.log.levels.INFO)
    return
  end

  -- Save current session
  local resession_ok, resession = pcall(require, "resession")
  if resession_ok then
    local buf_utils = require "astrocore.buffer"
    if buf_utils.is_valid_session() then
      resession.save(cwd, { dir = "dirsession", notify = false })
    end
  end

  -- Close all buffers
  vim.cmd "silent! %bdelete!"

  -- Change directory (tab-local)
  vim.cmd("tcd " .. vim.fn.fnameescape(target_path))

  -- Load target session
  local loaded = false
  if resession_ok then
    loaded = pcall(resession.load, target_path, { dir = "dirsession", silence_errors = true })
  end

  -- If no session, open Neo-tree or a blank buffer
  if not loaded then
    if require("astrocore").is_available "neo-tree.nvim" then
      vim.cmd "Neotree focus"
    else
      vim.cmd "edit ."
    end
  end

  -- Refresh worktree cache and notify
  vim.api.nvim_exec_autocmds("User", { pattern = "GwqWorktreeChanged" })
  vim.notify("Switched to: " .. target_path:gsub("^" .. vim.pesc(os.getenv "HOME"), "~"))
end

---Refresh worktree info cache (async)
local function refresh_worktree_info()
  local cwd = vim.fn.getcwd()
  vim.system({ gwq_bin, "list", "--json" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        worktree_cache = { branch = nil, is_worktree = false }
        return
      end
      local ok, worktrees = pcall(vim.json.decode, result.stdout)
      if not ok or not worktrees then
        worktree_cache = { branch = nil, is_worktree = false }
        return
      end
      local found = false
      for _, wt in ipairs(worktrees) do
        if wt.path == cwd then
          worktree_cache = { branch = wt.branch, is_worktree = not wt.is_main }
          found = true
          break
        end
      end
      if not found then worktree_cache = { branch = nil, is_worktree = false } end
    end)
  end)
end

-- ── Telescope Pickers ──────────────────────────────────────────────

local function ghq_repo_picker(opts)
  opts = opts or {}
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  run_cmd_lines(ghq_bin, { "list", "--full-path" }, function(repos)
    if not repos or #repos == 0 then
      vim.notify("No repositories found", vim.log.levels.WARN)
      return
    end

    local home = os.getenv "HOME"
    local ghq_root = home .. "/ghq/"

    pickers
      .new(opts, {
        prompt_title = "ghq Repositories",
        finder = finders.new_table {
          results = repos,
          entry_maker = function(repo_path)
            local display = repo_path:gsub("^" .. vim.pesc(home), "~")
            local relative = repo_path:gsub("^" .. vim.pesc(ghq_root), "")
            return {
              value = repo_path,
              display = display,
              ordinal = relative,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then switch_to_directory(selection.value) end
          end)
          return true
        end,
      })
      :find()
  end)
end

local function gwq_worktree_picker(opts)
  opts = opts or {}
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"

  run_cmd_json(gwq_bin, { "list", "--json" }, function(worktrees)
    if not worktrees or #worktrees == 0 then
      vim.notify("No worktrees found", vim.log.levels.WARN)
      return
    end

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 2 },
        { width = 45 },
        { width = 8 },
        { remaining = true },
      },
    }

    local cwd = vim.fn.getcwd()
    local home = os.getenv "HOME"

    pickers
      .new(opts, {
        prompt_title = "gwq Worktrees",
        finder = finders.new_table {
          results = worktrees,
          entry_maker = function(wt)
            return {
              value = wt,
              display = function(entry)
                local w = entry.value
                local indicator = w.path == cwd and ">" or " "
                local short_hash = w.commit_hash:sub(1, 7)
                local display_path = w.path:gsub("^" .. vim.pesc(home), "~")
                return displayer {
                  { indicator, "TelescopeResultsComment" },
                  { w.branch, "TelescopeResultsIdentifier" },
                  { short_hash, "TelescopeResultsNumber" },
                  { display_path, "TelescopeResultsComment" },
                }
              end,
              ordinal = wt.branch .. " " .. wt.path,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then switch_to_directory(selection.value.path) end
          end)
          map("i", "<C-d>", function()
            local selection = action_state.get_selected_entry()
            if not selection then return end
            local wt = selection.value
            if wt.path == cwd then
              vim.notify("Cannot remove current worktree", vim.log.levels.WARN)
              return
            end
            vim.ui.input({ prompt = "Remove worktree " .. wt.branch .. "? (y/N): " }, function(input)
              if input and input:lower() == "y" then
                vim.system({ gwq_bin, "remove", wt.path, "-f" }, { text = true }, function(result)
                  vim.schedule(function()
                    if result.code == 0 then
                      vim.notify("Removed: " .. wt.branch)
                      -- Re-open picker to refresh
                      actions.close(prompt_bufnr)
                      gwq_worktree_picker(opts)
                    else
                      vim.notify("Failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
                    end
                  end)
                end)
              end
            end)
          end)
          return true
        end,
      })
      :find()
  end)
end

local function gwq_status_picker(opts)
  opts = opts or {}
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"

  run_cmd_json(gwq_bin, { "status", "--json", "--no-fetch" }, function(data)
    if not data or not data.worktrees then
      vim.notify("No worktree status available", vim.log.levels.WARN)
      return
    end

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 10 },
        { width = 40 },
        { width = 8 },
        { remaining = true },
      },
    }

    local status_hl = {
      clean = "DiagnosticOk",
      modified = "DiagnosticWarn",
      stale = "DiagnosticError",
    }

    local home = os.getenv "HOME"
    local summary = data.summary or {}
    local title = string.format(
      "gwq Status (Total: %s, Modified: %s, Clean: %s)",
      summary.Total or "?",
      summary.Modified or "?",
      summary.Clean or "?"
    )

    pickers
      .new(opts, {
        prompt_title = title,
        finder = finders.new_table {
          results = data.worktrees,
          entry_maker = function(wt)
            return {
              value = wt,
              display = function(entry)
                local w = entry.value
                local gs = w.git_status or {}
                local changes = {}
                if (gs.modified or 0) > 0 then table.insert(changes, "M:" .. gs.modified) end
                if (gs.untracked or 0) > 0 then table.insert(changes, "?:" .. gs.untracked) end
                if (gs.staged or 0) > 0 then table.insert(changes, "S:" .. gs.staged) end
                local changes_str = #changes > 0 and table.concat(changes, " ") or ""
                local display_path = w.path:gsub("^" .. vim.pesc(home), "~")
                return displayer {
                  { w.status or "unknown", status_hl[w.status] or "Normal" },
                  { w.branch, "TelescopeResultsIdentifier" },
                  { changes_str, "DiagnosticWarn" },
                  { display_path, "TelescopeResultsComment" },
                }
              end,
              ordinal = wt.branch .. " " .. (wt.status or "") .. " " .. wt.path,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then switch_to_directory(selection.value.path) end
          end)
          return true
        end,
      })
      :find()
  end)
end

-- ── GwqAdd Command ─────────────────────────────────────────────────

local function gwq_add(branch_name)
  if not branch_name or branch_name == "" then
    vim.ui.input({ prompt = "New branch name: " }, function(input)
      if input and input ~= "" then gwq_add(input) end
    end)
    return
  end

  vim.notify("Creating worktree: " .. branch_name .. "...")
  vim.system({ gwq_bin, "add", "-b", branch_name }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("Failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      vim.notify("Worktree created: " .. branch_name)
      -- Get the new worktree path
      local path_result = vim.system({ gwq_bin, "get", branch_name }, { text = true }):wait()
      if path_result.code == 0 then
        local path = vim.trim(path_result.stdout)
        vim.ui.input({ prompt = "Switch to new worktree? (Y/n): " }, function(input)
          if not input or input == "" or input:lower() == "y" then switch_to_directory(path) end
        end)
      end
    end)
  end)
end

-- ── Plugin Specs ───────────────────────────────────────────────────

---@type LazySpec
return {
  -- Keymaps, commands, and autocmds via astrocore
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = function(_, opts)
      local maps = opts.mappings or {}

      -- Worktree group
      maps.n["<Leader>gw"] = { desc = "Worktrees" }
      maps.n["<Leader>gww"] = { function() gwq_worktree_picker() end, desc = "Switch worktree" }
      maps.n["<Leader>gwl"] = { function() gwq_worktree_picker() end, desc = "List worktrees" }
      maps.n["<Leader>gwa"] = { function() gwq_add() end, desc = "Add worktree" }
      maps.n["<Leader>gwr"] = { function() gwq_worktree_picker() end, desc = "Remove worktree (C-d)" }
      maps.n["<Leader>gws"] = { function() gwq_status_picker() end, desc = "Worktree status" }

      -- ghq repositories
      maps.n["<Leader>fp"] = { function() ghq_repo_picker() end, desc = "Find project (ghq)" }

      -- User commands
      opts.commands = opts.commands or {}
      opts.commands.GwqSwitch = { function() gwq_worktree_picker() end, desc = "Switch gwq worktree" }
      opts.commands.GwqAdd = {
        function(cmd) gwq_add(cmd.args ~= "" and cmd.args or nil) end,
        nargs = "?",
        desc = "Create gwq worktree",
      }
      opts.commands.GwqRemove = { function() gwq_worktree_picker() end, desc = "Remove gwq worktree" }
      opts.commands.GwqStatus = { function() gwq_status_picker() end, desc = "Show gwq worktree status" }
      opts.commands.GhqList = { function() ghq_repo_picker() end, desc = "Browse ghq repositories" }

      -- Autocmds for worktree cache refresh
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.gwq_worktree_refresh = {
        {
          event = "DirChanged",
          desc = "Refresh gwq worktree info",
          callback = refresh_worktree_info,
        },
        {
          event = "VimEnter",
          desc = "Initialize gwq worktree info",
          callback = refresh_worktree_info,
        },
        {
          event = "User",
          pattern = "GwqWorktreeChanged",
          desc = "Refresh worktree cache on switch",
          callback = refresh_worktree_info,
        },
      }
    end,
  },

  -- Heirline statusline: add worktree indicator after git_branch
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      if not opts.statusline then return end

      -- Insert worktree indicator after git_branch (index 2)
      local worktree_component = {
        condition = function() return worktree_cache.is_worktree end,
        provider = " wt ",
        hl = { fg = "#f5a97f", bold = true },
      }

      table.insert(opts.statusline, 3, worktree_component)
    end,
  },
}
