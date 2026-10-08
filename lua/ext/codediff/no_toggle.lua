-- :CodeDiff always opens a new diff tab. codediff's own command closes the
-- current tab when run inside a diff tab; `q` there still closes it.
--
-- codediff internals used:
--   codediff.commands       vscode_diff is replaced (the :CodeDiff command
--                           looks it up on every call)
--   codediff.ui.lifecycle   get_session is replaced for the one call that
--                           vscode_diff makes first, its "is this a diff
--                           tab" check
local M = {}

function M.setup()
  local commands = require("codediff.commands")
  local lifecycle = require("codediff.ui.lifecycle")
  local vscode_diff = commands.vscode_diff
  commands.vscode_diff = function(opts)
    local get_session = lifecycle.get_session
    lifecycle.get_session = function()
      lifecycle.get_session = get_session
      return nil
    end
    local ok, err = pcall(vscode_diff, opts)
    lifecycle.get_session = get_session
    if not ok then error(err, 0) end
  end
end

return M
