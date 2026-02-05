return {
  {
    "lunarvim/darkplus.nvim",
    lazy = false,
    name = "darkplus",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "darkplus"
    end
  }
}
