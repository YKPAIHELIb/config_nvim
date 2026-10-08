-- Extensions to codediff.nvim built on its internals, not its public API.
--
-- Every module here reaches into codediff's own modules (commands,
-- lifecycle sessions, the explorer and history panel objects, the history
-- tree, view.update, keymap help) and some replace functions on them. Any
-- codediff update can break them: after updating the plugin, check these
-- features first. The tested codediff
-- commit is pinned in lazy-lock.json.
--
-- setup() runs from codediff's lazy.nvim `config`, so only once codediff
-- itself is loaded. file_for.lua is required directly and works without it.
local M = {}

function M.setup()
  require("ext.codediff.no_toggle").setup()
  require("ext.codediff.close").setup()
  require("ext.codediff.shared_buffers").setup()
  require("ext.codediff.wheel_sync").setup()
  require("ext.codediff.history_compare").setup()
  require("ext.codediff.file_history").setup()
end

return M
