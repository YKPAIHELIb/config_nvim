-- Live markdown preview in the default browser, updated as you type with
-- scroll sync. Lua-only server; needs PowerShell on Windows.
return {
  "brianhuster/live-preview.nvim",
  cmd = { "LivePreview" },
  keys = {
    { "<leader>mp", "<cmd>LivePreview start<cr>", ft = "markdown", desc = "Markdown preview in browser" },
    { "<leader>mP", "<cmd>LivePreview close<cr>", desc = "Stop markdown preview" },
  },
}
