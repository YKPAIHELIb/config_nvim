-- Renders markdown in the buffer (headings, tables, code blocks, checkboxes,
-- callouts); the cursor line shows raw text for editing.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "markdown" },
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown buf_toggle<cr>", ft = "markdown", desc = "Toggle markdown rendering" },
  },
  opts = {},
}
