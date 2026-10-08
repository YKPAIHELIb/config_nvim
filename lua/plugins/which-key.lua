-- Popup listing the keys that can follow a typed prefix, from each mapping's
-- desc; buffer-local mappings show only in buffers that have them.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>s", group = "search" },
      { "<leader>w", group = "show" },
      { "<leader>m", group = "markdown" },
      { "<leader>d", group = "delete" },
    },
  },
}
