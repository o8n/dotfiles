-- LSP: lspconfig + mason + mason-lspconfig
return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "solargraph",
        "gopls",
        "ts_ls",
      },
      automatic_installation = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- LSP keymaps on attach
      local on_attach = function(_, bufnr)
        local opts = function(desc)
          return { buffer = bufnr, desc = desc }
        end
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("References"))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover"))
        vim.keymap.set("n", "<Leader>la", vim.lsp.buf.code_action, opts("Code action"))
        vim.keymap.set("n", "<Leader>lr", vim.lsp.buf.rename, opts("Rename"))
        vim.keymap.set("n", "<Leader>ld", vim.diagnostic.open_float, opts("Line diagnostics"))
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))
        vim.keymap.set("n", "<Leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, opts("Format"))
      end

      -- Setup servers via mason-lspconfig
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                diagnostics = { globals = { "vim" } },
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
              },
            },
          })
        end,
      })
    end,
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function()
      require("lsp_signature").setup()
    end,
  },
  -- Formatter
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      format_on_save = {
        timeout_ms = 1000,
        lsp_format = "fallback",
      },
    },
  },
  -- Mason tool installer (for formatters, linters, etc.)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {},
    },
  },
}
