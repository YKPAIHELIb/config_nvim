-- VSCode-style side-by-side diff. Lazy-loaded on :CodeDiff so it stays free
-- for `git difftool` and ad-hoc CLI compares (`nvim +"CodeDiff file a b"`).
-- The plugin auto-downloads a prebuilt C binary; no compiler needed.
-- Not loaded on Termux (git + delta there): `cond` keeps it installed and
-- pinned in lazy-lock.json, but its commands, keys and library download never
-- happen. lua/ext/codediff and config.tabs only act when codediff is loaded.

local function file_history() require("ext.codediff.file_history").open() end

return {
  "esmuellert/codediff.nvim",
  cond = not require("config.termux"),
  cmd = { "CodeDiff", "CodeDiffScratch", "CodeDiffToggleWS" },
  keys = {
    -- See lua/ext/codediff/file_history.lua.
    { "<leader>wh", file_history, desc = "File history" },
    { "<leader>wh", file_history, mode = "x", desc = "Line-range history" },
    -- What the current codediff tab compares, see lua/ext/codediff/tab_commits.lua.
    { "<leader>wi", function() require("ext.codediff.tab_commits").info() end, desc = "Diff tab: right commit details" },
    { "<leader>wl", function() require("ext.codediff.tab_commits").log() end, desc = "Diff tab: log left..right" },
    { "<leader>wL", function() require("ext.codediff.tab_commits").history() end, desc = "Diff tab: history left..right" },
  },
  config = function()
    -- VSCode Dark+-ish diff colors. Defined as dedicated groups so they don't
    -- bleed into nvim's general DiffAdd/DiffDelete (used by :diffthis, gitsigns, etc.).
    -- The line_* groups paint whole changed lines; the char_* groups paint the
    -- actual differing characters within those lines (brighter for contrast).
    vim.api.nvim_set_hl(0, "CodeDiffLineDelete", { bg = "#3F1F1F" })
    vim.api.nvim_set_hl(0, "CodeDiffLineInsert", { bg = "#1E3A1E" })
    vim.api.nvim_set_hl(0, "CodeDiffCharDelete", { bg = "#5A2929" })
    vim.api.nvim_set_hl(0, "CodeDiffCharInsert", { bg = "#2E5A2E" })

    local highlights = {
      line_delete = "CodeDiffLineDelete",
      line_insert = "CodeDiffLineInsert",
      char_delete = "CodeDiffCharDelete",
      char_insert = "CodeDiffCharInsert",
    }
    local ignore_ws = true -- matches VSCode's default; treats indent-only shifts as unchanged

    local function apply()
      require("codediff").setup({
        highlights = highlights,
        diff = {
          layout = "side-by-side",
          ignore_trim_whitespace = ignore_ws,
        },
        explorer = {
          view_mode = "tree",
        },
        history = {
          view_mode = "tree",
        },
        -- Closing is handled in lua/ext/codediff/close.lua.
        keymaps = {
          view = { quit = false },
        },
      })
    end
    apply()

    -- :CodeDiffToggleWS — flip whitespace sensitivity. Re-run your :CodeDiff command
    -- after toggling for the change to show in an already-open session.
    vim.api.nvim_create_user_command("CodeDiffToggleWS", function()
      ignore_ws = not ignore_ws
      apply()
      vim.notify("CodeDiff: ignore_trim_whitespace = " .. tostring(ignore_ws), vim.log.levels.INFO)
    end, { desc = "Toggle CodeDiff's ignore_trim_whitespace setting" })

    -- :CodeDiffScratch [ext] — open a fresh side-by-side canvas backed by two empty temp files.
    -- Diff updates live as you paste/type. Optional arg sets the file extension for syntax highlighting.
    vim.api.nvim_create_user_command("CodeDiffScratch", function(opts)
      local ext = opts.args ~= "" and opts.args or "txt"
      local left  = vim.fn.tempname() .. "." .. ext
      local right = vim.fn.tempname() .. "." .. ext
      vim.fn.writefile({}, left)
      vim.fn.writefile({}, right)
      vim.cmd(string.format("CodeDiff file %s %s", left, right))
    end, {
      nargs = "?",
      desc = "Open CodeDiff with two empty scratch files (optional file extension)",
    })

    -- Wheel-synced panes and history-panel compare; these rely on codediff
    -- internals, see lua/ext/codediff/.
    require("ext.codediff").setup()
  end,
}
