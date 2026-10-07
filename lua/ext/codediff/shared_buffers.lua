-- Keep codediff tabs independent when one of them closes.
--
-- codediff internals used: User CodeDiffClose (fired at the start of a
-- session's cleanup, data.tabpage); codediff.ui.lifecycle.session
-- get_active_diffs(); session fields original_bufnr, modified_bufnr,
-- result_bufnr, original_revision, modified_revision.
--
-- Virtual buffers (a file at a git revision) are named by repo, revision and
-- path, so two tabs showing the same file version share one buffer. Closing
-- a tab force-deletes its virtual buffers, which also closes that buffer's
-- window in the other tab; entering that tab later drops its session because
-- a buffer is gone, leaving a dead explorer. Cleanup deletes a buffer only
-- when its side's revision marks it virtual, so clearing the revision on the
-- closing session keeps buffers that another session still shows. Clearing
-- that session's highlights and keymaps on a shared buffer is harmless: a
-- tab re-renders its diff and re-applies its keymaps whenever it is entered.
local M = {}

local function used_elsewhere(bufnr, closing_tab, sessions)
  for tab, s in pairs(sessions) do
    if tab ~= closing_tab
      and (s.original_bufnr == bufnr or s.modified_bufnr == bufnr or s.result_bufnr == bufnr) then
      return true
    end
  end
  return false
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("CodeDiffSharedBuffers", { clear = true }),
    pattern = "CodeDiffClose",
    callback = function(args)
      local tab = args.data and args.data.tabpage
      if not tab then return end
      local sessions = require("codediff.ui.lifecycle.session").get_active_diffs()
      local closing = sessions[tab]
      if not closing then return end
      if used_elsewhere(closing.original_bufnr, tab, sessions) then
        closing.original_revision = nil
      end
      if used_elsewhere(closing.modified_bufnr, tab, sessions) then
        closing.modified_revision = nil
      end
    end,
  })
end

return M
