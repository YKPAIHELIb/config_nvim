return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      -- Neovim's libuv bindings (vim.uv.*) — loaded when you reference vim.uv
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  },
}
