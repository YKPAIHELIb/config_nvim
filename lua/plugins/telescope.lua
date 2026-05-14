return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  keys = {
    { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
    { "<leader>sg", function() require("telescope.builtin").git_files() end, desc = "Git Files" },
    { "<leader>sr", function() require("telescope.builtin").live_grep() end, desc = "Live Grep" },
    { "<leader>sb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
    { "<leader>sh", function() require("telescope.builtin").help_tags() end, desc = "Help Tags" },
  },
  config = function()
    require("telescope").setup()

    -- <leader>st / <leader>sm work only with LSP; attached lazily on LspAttach
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        vim.keymap.set("n", "<leader>st", function()
          require("telescope.builtin").lsp_workspace_symbols()
        end, { buffer = args.buf, desc = "Workspace Symbols (LSP)" })
        vim.keymap.set("n", "<leader>sm", function()
          require("telescope.builtin").lsp_document_symbols()
        end, { buffer = args.buf, desc = "Document Symbols / Members (LSP)" })
      end,
    })
  end,
}
