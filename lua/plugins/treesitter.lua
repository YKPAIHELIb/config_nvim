return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- the rewrite; `master` is the legacy line, kept only for Nvim 0.11 compat
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },

    opts = {
      ensure_installed = { "c_sharp", "lua", "vim", "vimdoc", "query" },

      -- auto_install works only for parsers with pre-generated C sources.
      -- Some languages require the tree-sitter CLI (Node.js) to generate parsers.
      auto_install = true,

      highlight = {
        enable = true,
        disable = function(_, bufnr)
          return vim.api.nvim_buf_line_count(bufnr) > 5000
        end,
      },
    },
  },
}
