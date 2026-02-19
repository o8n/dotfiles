-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.ruby" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.typescript" },
  -- { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },  -- replaced by glow.nvim
  { import = "astrocommunity.recipes.auto-session-restore" }, -- セッション自動保存・復元
}
