-- File on disk behind a window, and whether the window shows that file's
-- lines. A codediff pane resolves through its session: virtual (git
-- revision) panes map to the tracked path, and the explorer or history
-- panel maps to the modified side. Works without loading codediff.
--
-- codediff internals used:
--   codediff.ui.lifecycle   get_session, get_windows, get_paths,
--                           get_git_context
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
  local orig_path, mod_path = lifecycle.get_paths(tab)
  local path = win == orig_win and orig_path or mod_path
  if not path or path == "" then return nil end
  local ctx = lifecycle.get_git_context(tab)
  if vim.fn.isabsolutepath(path) == 0 and ctx and ctx.git_root then
    path = ctx.git_root .. "/" .. path
  end
  return path, win == orig_win or win == mod_win
end
