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

    vim.lsp.config("rust_analyzer", {
      settings = {
        ["rust-analyzer"] = {
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
          },
          checkOnSave = true,
          check = { command = "clippy" },
          procMacro = { enable = true },
          inlayHints = {
            enable = true,
            bindingModeHints = { enable = true },
            chainingHints = { enable = true },
            closingBraceHints = { enable = true, minLines = 25 },
            closureReturnTypeHints = { enable = "with_block" },
            lifetimeElisionHints = { enable = "skip_trivial" },
            parameterHints = { enable = true },
            reborrowHints = { enable = "mutable" },
            typeHints = {
              enable = true,
              hideClosureInitialization = false,
              hideNamedConstructor = false,
            },
          },
          hover = {
            actions = { enable = true },
          },
        },
      },
    })

    vim.lsp.enable("lua_ls")
    vim.lsp.enable("rust_analyzer")

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

    -- Wraps a location request so that from a tool tab (see config.tabs)
    -- results in the current file stay in place while results in other files
    -- open in the editing tab. Elsewhere the stock behaviour runs untouched.
    local function routed(request, always_list)
      return function()
        local tabs = require("config.tabs")
        local win = vim.api.nvim_get_current_win()
        if not tabs.is_redirected(win) then return request() end
        request({ on_list = tabs.location_handler(win, always_list) })
      end
    end

    local nav = {
      { { "gd", "<C-]>" }, vim.lsp.buf.definition },
      { { "gD" }, vim.lsp.buf.declaration },
      { { "gi", "gri" }, vim.lsp.buf.implementation },
      { { "grt" }, vim.lsp.buf.type_definition },
      { { "gr", "grr" }, function(opts) vim.lsp.buf.references(nil, opts) end, true },
    }

    -- keymaps on attach
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("n", "<leader>i", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
        vim.keymap.set("n", "<A-CR>", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>l", vim.diagnostic.open_float, opts) -- was gl; moved off g* because illuminate uses gl for next reference

        -- LSP navigation
        for _, entry in ipairs(nav) do
          for _, lhs in ipairs(entry[1]) do
            vim.keymap.set("n", lhs, routed(entry[2], entry[3]), opts)
          end
        end
        vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)

        -- auto-enable inlay hints when the server provides them
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
        end
      end,
    })
  end,
}
