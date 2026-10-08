-- Closing codediff tabs. codediff's own quit key is turned off in
-- plugins/codediff.lua: it maps `q` on every buffer of the diff, including
-- real file buffers that other tabs show too, so `q` there would not record
-- macros and would close whatever tab it was pressed in. Here `q`
-- closes the tab only from the explorer and history panels; anywhere in
-- the tab <leader>q does (see config.tabs).
--
-- codediff internals used:
--   codediff.ui.lifecycle   get_session, confirm_close_with_unsaved (asks
--                           about unsaved merge results)
--   panel filetypes         codediff-explorer, codediff-history
local M = {}

-- Closes codediff tab `tab`. The last tab is swapped for an empty one, so
-- closing never quits Neovim.
function M.close(tab)
  local lifecycle = require("codediff.ui.lifecycle")
  if not lifecycle.get_session(tab) or not lifecycle.confirm_close_with_unsaved(tab) then return end
  if #vim.api.nvim_list_tabpages() == 1 then vim.cmd("tabnew") end
  vim.cmd(vim.api.nvim_tabpage_get_number(tab) .. "tabclose")
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
