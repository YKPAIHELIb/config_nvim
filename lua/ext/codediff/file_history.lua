-- History of the file in the current window, which may be a codediff pane
-- or a blame tab's window. From a pane showing a git revision, or a blamed
-- line, the history panel opens on the newest listed commit at or before
-- that revision that touches the file, i.e. the commit that produced the
-- version on screen (for a blamed line, the blamed commit itself).
-- Elsewhere it opens on the newest commit, as codediff does.
--
-- An explicit HEAD range lifts codediff's default 100-commit limit, so the
-- whole history is listed. From visual mode only commits touching the
-- selected lines are listed.
--
-- codediff internals used:
--   codediff.commands       vscode_diff (the :CodeDiff handler), called with
--                           fargs/range so the path needs no escaping
--   codediff.ui.lifecycle   get_session: original_win, original_revision,
--                           modified_revision, git_root
--   codediff.ui.history     create is replaced; the panel object's
--                           on_file_select, tree, winid, is_single_file_mode
--                           and the commit fields hash / file_path
local M = {}

local file_for = require("ext.codediff.file_for")

-- Set by open() for the history panel it is about to create:
-- { path = normalized absolute path, commits = set of full hashes }.
local pending

local function norm(path)
  local p = vim.fs.normalize(path)
  return vim.fn.has("win32") == 1 and p:lower() or p
end

-- Git revision shown in `win` when it is a codediff pane: the left pane
-- shows original_revision, the right pane and the side panel
-- modified_revision. Working tree and index sides give nil.
local function pane_revision(win)
  local session = require("codediff.ui.lifecycle").get_session(vim.api.nvim_win_get_tabpage(win))
  if not session or not session.git_root then return nil end
  local rev = win == session.original_win and session.original_revision or session.modified_revision
  if not rev or rev == "WORKING" or rev:match("^:") then return nil end
  return rev
end

-- In a blame tab (see plugins/blame.lua) both windows show the same lines;
-- the commit is the blame line's at the cursor row. Lines not yet committed
-- are blamed on an all-zero hash.
local function blame_source(win)
  local tab = vim.api.nvim_win_get_tabpage(win)
  local file, blame_win = vim.t[tab].blame_file, vim.t[tab].blame_win
  if not file or not blame_win or not vim.api.nvim_win_is_valid(blame_win) then return nil end
  if win ~= blame_win and norm(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))) ~= norm(file) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local line = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(blame_win), row - 1, row, false)[1] or ""
  local hash = line:match("^(%x+)")
  return file, hash and not hash:match("^0+$") and hash or nil
end

-- File and git revision for the current window: a blame tab's file and
-- the blamed commit, or a file (possibly behind a codediff pane) and the
-- revision the pane shows.
local function source(win)
  local file, rev = blame_source(win)
  if file then return file, rev end
  file = file_for(win)
  return file, file and pane_revision(win)
end

-- The panel selects its first commit from a callback scheduled inside
-- create(), through history.on_file_select; that first call is redirected
-- to the wanted commit.
local function hook_create()
  local history_module = require("codediff.ui.history")
  local create = history_module.create
  history_module.create = function(commits, git_root, tabpage, width, opts)
    local history = create(commits, git_root, tabpage, width, opts)
    -- The panel window is split off the window current when history opens
    -- and keeps its window options. Opened from a diff pane it would keep
    -- scrollbind and scroll along with the new diff, moving its cursor.
    if history and history.winid and vim.api.nvim_win_is_valid(history.winid) then
      vim.wo[history.winid].scrollbind = false
      vim.wo[history.winid].cursorbind = false
    end
    local want = pending
    if not want or not history or not history.is_single_file_mode
      or norm(git_root .. "/" .. opts.file_path) ~= want.path then
      return history
    end
    pending = nil
    local target
    for _, commit in ipairs(commits) do
      if want.commits[commit.hash] then
        target = commit
        break
      end
    end
    if not target then return history end

    local select = history.on_file_select
    history.on_file_select = function(_, ...)
      history.on_file_select = select
      local result = select({
        path = target.file_path or opts.file_path,
        commit_hash = target.hash,
        git_root = git_root,
      }, ...)
      local node = history.tree:get_node("commit:" .. target.hash)
      if node and node._line and vim.api.nvim_win_is_valid(history.winid) then
        vim.api.nvim_win_set_cursor(history.winid, { node._line, 0 })
      end
      return result
    end
    return history
  end
end

function M.open()
  local path, rev = source(vim.api.nvim_get_current_win())
  if not path then
    vim.notify("codediff: no file for this window", vim.log.levels.WARN)
    return
  end

  pending = nil
  if rev then
    local res = vim.system({ "git", "rev-list", rev, "--", path }, { cwd = vim.fs.dirname(path), text = true }):wait()
    if res.code == 0 then
      local commits = {}
      for hash in res.stdout:gmatch("%x+") do commits[hash] = true end
      pending = { path = norm(path), commits = commits }
    end
  end

  local opts = { fargs = { "history", "HEAD", path }, range = 0 }
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local a, b = vim.fn.line("v"), vim.fn.line(".")
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    opts.range, opts.line1, opts.line2 = 2, math.min(a, b), math.max(a, b)
  end
  require("codediff.commands").vscode_diff(opts)
end

function M.setup()
  hook_create()
end

return M
