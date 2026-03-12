-- Debug Adapter Protocol
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "leoluz/nvim-dap-go",
    },
    keys = {
      { "<Leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<Leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<Leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<Leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<Leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<Leader>dr", function() require("dap").repl.open() end, desc = "Open REPL" },
      { "<Leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
    },
    config = function()
      local dapui = require("dapui")
      dapui.setup()
      require("dap-go").setup()

      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
}
