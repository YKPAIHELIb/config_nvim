return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
    { "<leader>sg", function() require("telescope.builtin").git_files() end, desc = "Git Files" },
    { "<leader>sr", function() require("telescope.builtin").live_grep() end, desc = "Live Grep" },
    { "<leader>sb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
    { "<leader>sh", function() require("telescope.builtin").help_tags() end, desc = "Help Tags" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup() -- no defaults

    -- Reliable LSP keymap: only attach when LSP is available
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local buf = args.buf
        vim.keymap.set("n", "<leader>st", function()
          local ok, tb = pcall(require, "telescope.builtin")
          if ok then
            tb.lsp_workspace_symbols()
          end
        end, { buffer = buf, desc = "Workspace Symbols (LSP)" })
      end,
    })
  end,
}
