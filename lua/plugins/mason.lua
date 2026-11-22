-- Mason installs LSP servers (and other tools) outside the system package manager.
-- Skipped on Termux: mason's prebuilt servers are glibc Linux builds that
-- Android can't run. There termux_setup's initial_setup.sh installs
-- lua-language-server and rust-analyzer with pkg, and lsp.lua finds them on
-- PATH. `cond` (not `enabled`) keeps both plugins in lazy-lock.json, so the
-- lockfile is the same on every machine.
local termux = require("config.termux")

return {
  {
    "williamboman/mason.nvim",
    cond = not termux,
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    cond = not termux,
    dependencies = { "williamboman/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = { "lua_ls" },
      automatic_enable = false, -- we enable explicitly in lsp.lua
    },
  },
}
