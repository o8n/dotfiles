---@type LazySpec
return {
  "akinsho/toggleterm.nvim",
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        if not opts.autocmds then opts.autocmds = {} end
        opts.autocmds.pdf_viewer = {
          {
            event = "BufReadCmd",
            pattern = "*.pdf",
            desc = "Open PDF files with tdf in a floating terminal",
            callback = function(args)
              local filepath = vim.api.nvim_buf_get_name(args.buf)
              if filepath == "" then return end
              vim.schedule(function()
                vim.api.nvim_buf_delete(args.buf, { force = true })
                local Terminal = require("toggleterm.terminal").Terminal
                local tdf = Terminal:new({
                  cmd = "tdf " .. vim.fn.shellescape(filepath),
                  direction = "float",
                  float_opts = {
                    border = "rounded",
                    width = function() return math.floor(vim.o.columns * 0.9) end,
                    height = function() return math.floor(vim.o.lines * 0.9) end,
                  },
                  close_on_exit = true,
                })
                tdf:toggle()
              end)
            end,
          },
        }
      end,
    },
  },
}
