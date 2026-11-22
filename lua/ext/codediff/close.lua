-- Closing codediff tabs. codediff's own quit key is turned off in
-- plugins/codediff.lua: it maps `q` on every buffer of the diff, including
-- real file buffers that other tabs show too, so `q` there would not record
-- macros and would close whatever tab it was pressed in. codediff has no
-- per-panel quit key, so here `q` closes the tab only from the explorer and
-- history panels; anywhere in the tab <leader>q does (see config.tabs).
--
-- codediff internals used:
--   codediff.ui.lifecycle   get_session, close (what codediff's own quit key
--                           runs: asks about unsaved merge results, swaps the
--                           last tab for an empty one so Neovim stays open,
--                           and quits for --exit-on-close, e.g. difftool)
--   panel filetypes         codediff-explorer, codediff-history
local M = {}

-- Closes codediff tab `tab`.
function M.close(tab)
  local lifecycle = require("codediff.ui.lifecycle")
  if not lifecycle.get_session(tab) then return end
  lifecycle.close(tab)
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CodeDiffPanelClose", { clear = true }),
    pattern = { "codediff-explorer", "codediff-history" },
    callback = function(args)
      vim.keymap.set("n", "q", function() M.close(vim.api.nvim_get_current_tabpage()) end,
        { buffer = args.buf, nowait = true, silent = true, desc = "Close codediff tab" })
    end,
  })
end

return M
