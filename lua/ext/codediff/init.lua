-- Extensions to codediff.nvim built on its internals, not its public API.
--
-- The modules here reach into codediff's own modules (lifecycle sessions,
-- the explorer and history panel objects, the history tree, view.update,
-- keymap help) and some replace functions on them; new_tab.lua only runs
-- :CodeDiff. Any codediff update can break them: after
-- updating the plugin, check these features first. The tested codediff
-- commit is pinned in lazy-lock.json.
--
-- Loaded from codediff's lazy.nvim `config`, so only once codediff itself is
-- loaded.
local M = {}

function M.setup()
  require("ext.codediff.shared_buffers").setup()
  require("ext.codediff.wheel_sync").setup()
  require("ext.codediff.history_compare").setup()
end

return M
