-- Mason installs LSP servers (and other tools) outside the system package manager.
-- This file is master-only: termux/Android can't run most LSP binaries from mason,
-- so on that branch the file is absent and lsp.lua relies on already-installed servers.
return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = { "lua_ls" },
      automatic_enable = false, -- we enable explicitly in lsp.lua
    },
  },
}
