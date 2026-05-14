return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lsp",

    -- snippets
    { "L3MON4D3/LuaSnip", version = "v2.*" },
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    require("luasnip/loaders/from_vscode").lazy_load()

    local check_backspace = function()
      local col = vim.fn.col(".") - 1
      return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
    end

    --   פּ ﯟ   some other good icons
    local kind_icons = {
      Text = "󰊄",
      Method = "m",
      Function = "󰊕",
      Constructor = "",
      Field = "",
      Variable = "󰫧",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "",
      Value = "",
      Enum = "",
      Keyword = "󰌆",
      Snippet = "",
      Color = "",
      File = "",
      Reference = "",
      Folder = "",
      EnumMember = "",
      Constant = "",
      Struct = "",
      Event = "",
      Operator = "",
      TypeParameter = "󰉺",
    }

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,noinsert", -- highlight first item, but don't auto-insert until confirmed
      },
      preselect = cmp.PreselectMode.Item, -- honor server-side preselect hints too

      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      mapping = {
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-k>"] = cmp.mapping.select_prev_item(),

        -- Arrow keys navigate completions only when the menu is open;
        -- otherwise they fall through to normal line motion.
        ["<Down>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_next_item() else fallback() end
        end, { "i" }),
        ["<Up>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_prev_item() else fallback() end
        end, { "i" }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-1),
        ["<C-f>"] = cmp.mapping.scroll_docs(1),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),

        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expandable() then
            luasnip.expand()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif check_backspace() then
            fallback()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      },

      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, item)
          item.kind = kind_icons[item.kind] or item.kind
          item.menu = ({
            nvim_lsp = "[LSP]",
            lazydev = "[NvimAPI]",
            buffer = "[Buffer]",
            path = "[Path]",
            luasnip = "[Snippet]",
          })[entry.source.name]
          return item
        end,
      },

      sources = {
        { name = "lazydev", group_index = 0 }, -- prioritized for Neovim Lua API completions
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "path" },
      },

      window = {
        documentation = cmp.config.window.bordered(),
      },

      experimental = {
        ghost_text = true,
      },
    })

    -- `/` search
    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    -- `:` command line
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "path" },
        { name = "cmdline" },
      },
    })
  end,
}
