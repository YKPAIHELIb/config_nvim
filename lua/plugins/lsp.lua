return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "williamboman/mason.nvim", build = ":MasonUpdate", opts = {} },
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls" },
      automatic_enable = false, -- we enable explicitly below
    })

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

    -- keymaps on attach (matches your existing muscle memory)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
        vim.keymap.set("n", "<A-CR>", vim.lsp.buf.code_action, opts)
        -- vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts) -- conflicts with illuminate next-reference (gl); rethink later

        -- LSP navigation (these were provided by lsp-zero in your old config)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
      end,
    })
  end,
}
