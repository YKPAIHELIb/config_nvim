return {
  "RRethy/vim-illuminate",
  event = "VeryLazy",
  keys = {
    { "gl", function() require("illuminate").goto_next_reference(true) end, desc = "Next reference (illuminate)" },
    { "gh", function() require("illuminate").goto_prev_reference(true) end, desc = "Prev reference (illuminate)" },
  },
  config = function()
    require("illuminate").configure({
      providers = { "lsp", "regex" }, -- treesitter provider no-ops on nvim-treesitter `main`; see RRethy/vim-illuminate#247
      delay = 200,
    })
  end,
}
