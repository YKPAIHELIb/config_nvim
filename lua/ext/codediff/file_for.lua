-- File on disk behind a window, and whether the window shows that file's
-- lines. A codediff pane resolves through its session: virtual (git
-- revision) panes map to the tracked path, and the explorer or history
-- panel maps to the modified side. Works without loading codediff.
--
-- codediff internals used:
--   codediff.ui.lifecycle   get_session, get_windows, get_paths (Path refs
--                           { absolute, relative }), get_git_context
return function(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype == "" and name ~= "" and not name:match("^codediff://") then
    return name, true
  end
  local lifecycle = package.loaded["codediff.ui.lifecycle"]
  local tab = vim.api.nvim_win_get_tabpage(win)
  if not lifecycle or not lifecycle.get_session(tab) then return nil end
  local orig_win, mod_win = lifecycle.get_windows(tab)
  local orig, mod = lifecycle.get_paths(tab)
  local ref = win == orig_win and orig or mod
  if not ref then return nil end
  local path = ref.absolute
  if not path or path == "" then
    local ctx = lifecycle.get_git_context(tab)
    if not ref.relative or ref.relative == "" or not (ctx and ctx.git_root) then return nil end
    path = ctx.git_root .. "/" .. ref.relative
  end
  return path, win == orig_win or win == mod_win
end
