-- Extensions to codediff.nvim built on its internals, not its public API.
--
-- Every module here reaches into codediff's own modules (lifecycle sessions,
-- the history panel object, its tree, view.update, keymap help) and some
-- replace functions on them. Any codediff update can break them: after
-- updating the plugin, check these features first. The tested codediff
-- commit is pinned in lazy-lock.json.
--
-- Loaded from codediff's lazy.nvim `config`, so only once codediff itself is
-- loaded.
local M = {}

function M.setup()
  require("ext.codediff.wheel_sync").setup()
  require("ext.codediff.history_compare").setup()
end

return M
