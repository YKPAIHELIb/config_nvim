return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
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

        -- Tab confirms (same as Enter). Cycling is done with arrows or <C-j>/<C-k>.
        -- Outside an open menu, Tab still drives snippet expand/jump.
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = true })
          elseif luasnip.expandable() then
            luasnip.expand()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),

        -- S-Tab no longer cycles cmp; it only jumps backward through snippet placeholders.
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(-1) then
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

    -- Arrows in cmdline should recall history without popping cmp. Suppressing via
    -- cmp's `enabled` callback races with cmp's CmdlineChanged handler. Instead we
    -- temporarily add CmdlineChanged to `eventignore` so vim doesn't fire the autocmd
    -- at all during the recall, then schedule its removal for the next event-loop tick.
    local function recall_without_cmp(fallback)
      vim.opt.eventignore:append("CmdlineChanged")
      fallback()
      vim.schedule(function() vim.opt.eventignore:remove("CmdlineChanged") end)
    end

    -- Cmdline behavior:
    --   - First item is visually preselected.
    --   - <Tab> confirms the (pre)selection. <CR> always executes literally —
    --     so `:w<CR>`, `:q<CR>` etc. work without a second keypress.
    --   - Arrow keys and <C-j>/<C-k> cycle through items. <S-Tab> is inert.
    local cmdline_mapping = cmp.mapping.preset.cmdline({
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm({ select = true })
        else
          fallback()
        end
      end, { "c" }),
      ["<CR>"] = cmp.mapping(function(fallback) fallback() end, { "c" }),
      -- Arrows: navigate the cmp menu when it's visible, otherwise recall history
      -- without triggering cmp's auto-show on the recall's text change.
      ["<Down>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_next_item() else recall_without_cmp(fallback) end
      end, { "c" }),
      ["<Up>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_prev_item() else recall_without_cmp(fallback) end
      end, { "c" }),
      ["<C-j>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_next_item() else fallback() end
      end, { "c" }),
      ["<C-k>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_prev_item() else fallback() end
      end, { "c" }),
    })

    local cmdline_completion_opts = {
      preselect = cmp.PreselectMode.Item,
      completion = { completeopt = "menu,menuone,noinsert" },
      mapping = cmdline_mapping,
    }

    -- `/` search
    cmp.setup.cmdline("/", vim.tbl_extend("force", cmdline_completion_opts, {
      sources = { { name = "buffer" } },
    }))

    -- `:` command line
    cmp.setup.cmdline(":", vim.tbl_extend("force", cmdline_completion_opts, {
      sources = { { name = "path" }, { name = "cmdline" } },
    }))
  end,
}
