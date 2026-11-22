-- :CodeDiff always opens a new diff tab. codediff's own command closes the
-- current tab when run without arguments inside a diff tab; `q` in the
-- panels and <leader>q still close it (see close.lua).
--
-- codediff internals used:
--   codediff.commands       vscode_diff is replaced (the :CodeDiff command
--                           looks it up on every call)
--   codediff.ui.lifecycle   get_session is replaced for the one call that
--                           vscode_diff makes first when it has no arguments,
--                           its "is this a diff tab" check. With arguments
--                           vscode_diff never toggles and makes no such call,
--                           so it runs untouched.
local M = {}

function M.setup()
  local commands = require("codediff.commands")
  local lifecycle = require("codediff.ui.lifecycle")
  local vscode_diff = commands.vscode_diff
  commands.vscode_diff = function(opts)
    if #(opts.fargs or {}) > 0 then return vscode_diff(opts) end
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
