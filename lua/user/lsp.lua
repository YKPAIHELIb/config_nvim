local lsp_status_ok, lsp_zero = pcall(require, "lsp-zero")
if not lsp_status_ok then
  return
end

lsp_zero.preset("recommended")

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions

  local opts = {buffer = bufnr, remap = false}

  vim.keymap.set("n", "<leader>i", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>r", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format() end, opts)
  vim.keymap.set("n", "<a-cr>", function() vim.lsp.buf.code_action() end, opts)

  lsp_zero.default_keymaps({buffer = bufnr})
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
      "lua_ls"
  },
  handlers = {
    lsp_zero.default_setup,
  },
})

require('lspconfig').lua_ls.setup {
    settings = {
        Lua = {
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {'vim'},
            },
        }
    }
}

