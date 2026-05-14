return {
  "echasnovski/mini.files",
  keys = {
    { "<leader>e", function() require("mini.files").open() end, desc = "Open MiniFiles" },
    { "<leader>E", function() require("mini.files").open(vim.api.nvim_buf_get_name(0)) end, desc = "Open MiniFiles (current file)" },
  },
  config = function()
    require("mini.files").setup()
  end,
}
