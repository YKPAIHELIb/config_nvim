return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    -- give every server cmp-nvim-lsp's capabilities so completion lights up
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    vim.lsp.config("*", { capabilities = capabilities })

    -- per-server overrides
    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
        },
      },
    })

    vim.lsp.enable("lua_ls")

    -- :LspEnable <server>  — start a server on demand (for languages not in the auto-enable list).
    -- Tab-completes against every server nvim-lspconfig knows about.
    vim.api.nvim_create_user_command("LspEnable", function(args)
      vim.lsp.enable(args.args)
      vim.notify("LSP enabled: " .. args.args, vim.log.levels.INFO)
    end, {
      nargs = 1,
      desc = "Enable an LSP server for this session",
      complete = function(arg)
        local seen = {}
        for _, f in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
          local name = vim.fn.fnamemodify(f, ":t:r")
          if name:find(arg, 1, true) then
            seen[name] = true
          end
        end
        return vim.tbl_keys(seen)
      end,
    })

    -- keymaps on attach
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
        vim.keymap.set("n", "<A-CR>", vim.lsp.buf.code_action, opts)
        -- vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts) -- conflicts with illuminate next-reference (gl); rethink later

        -- LSP navigation
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
      end,
    })
  end,
}
