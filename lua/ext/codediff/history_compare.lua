-- Compare any two commits from codediff's history panel. `m` marks a row;
-- `d` diffs the file between the marked row and the row under the cursor in
-- this tab, `c` opens the whole-commit comparison in a new tab. In visual
-- mode both compare the first and last selected rows. The older commit goes
-- on the left. The panel shows the marked row and the old/new rows of the
-- last compare, and the keys are listed in codediff's g? help.
--
-- codediff internals used:
--   codediff.ui.lifecycle      get_session, get_explorer (the history panel
--                              object); set_tab_keymap is replaced
--   history panel object       tree, bufnr, winid, git_root, opts,
--                              is_single_file_mode; on_file_select and
--                              tree.render are replaced
--   history tree nodes         get_node(line|id), get_id(), _line, data.*
--                              and ids "commit:<hash>" / "file:<hash>:<path>"
--   codediff.ui.view           update(tabpage, session_config, jump)
--   codediff.config            options.keymaps.view, options.diff
--   codediff.ui.keymap_help    toggle is replaced; session._help_win
local M = {}

local compare_keys = {
  { "m", "Mark commit/file for compare" },
  { "d", "File diff: marked vs cursor (visual: first vs last)" },
  { "c", "Commits diff: marked vs cursor (visual: first vs last)" },
}

-- Per history panel: the `m` row and the two rows of the last compare.
local panels = setmetatable({}, { __mode = "k" })
local paint_ns = vim.api.nvim_create_namespace("codediff-history-compare")

-- A file row hidden under a collapsed commit is shown on its commit row.
local function line_of(history, entry)
  local node = history.tree:get_node(entry.id)
  if node and node._line then return node._line end
  local commit = history.tree:get_node("commit:" .. entry.hash)
  return commit and commit._line
end

local function paint(history)
  local state, buf = panels[history], history.bufnr
  if not state or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, paint_ns, 0, -1)
  local function put(entry, opts)
    local line = entry and line_of(history, entry)
    if line then
      vim.api.nvim_buf_set_extmark(buf, paint_ns, line - 1, 0, vim.tbl_extend("force", { priority = 10000 }, opts))
    end
  end
  local old_label, new_label = "◀ old ", "▶ new "
  put(state.old, {
    virt_text = { { old_label, "CodeDiffCharDelete" } },
    virt_text_pos = "inline",
    line_hl_group = "CodeDiffLineDelete",
  })
  put(state.new, {
    virt_text = { { new_label, "CodeDiffCharInsert" } },
    virt_text_pos = "inline",
    line_hl_group = "CodeDiffLineInsert",
  })

  -- codediff pads its selected row with spaces to the window width, so
  -- end-of-line text would land off-screen; the marker is placed at a
  -- window column right after the row's real text instead.
  local mark_line = state.mark and line_of(history, state.mark)
  if mark_line then
    local label = " ● marked"
    local text = vim.api.nvim_buf_get_lines(buf, mark_line - 1, mark_line, false)[1] or ""
    local col = vim.fn.strdisplaywidth((text:gsub("%s+$", "")))
    if state.old and line_of(history, state.old) == mark_line then
      col = col + vim.fn.strdisplaywidth(old_label)
    elseif state.new and line_of(history, state.new) == mark_line then
      col = col + vim.fn.strdisplaywidth(new_label)
    end
    local win = history.winid
    if win and vim.api.nvim_win_is_valid(win) then
      local info = vim.fn.getwininfo(win)[1]
      col = math.min(col, info.width - info.textoff - vim.fn.strdisplaywidth(label))
    end
    put(state.mark, { virt_text = { { label, "WarningMsg" } }, virt_text_win_col = math.max(col, 0) })
  end
end

-- The tree rewrites every line (dropping foreign extmarks) on each render,
-- so painting follows every render. Selecting a row with <CR> shows
-- codediff's own single-commit diff, which ends the compare.
local function ensure_hooks(history)
  if panels[history] then return end
  panels[history] = {}
  local tree = history.tree
  local render = tree.render
  tree.render = function(self, ...)
    render(self, ...)
    paint(history)
  end
  local on_file_select = history.on_file_select
  history.on_file_select = function(...)
    panels[history].old, panels[history].new = nil, nil
    return on_file_select(...)
  end
end

local function history_panel()
  local lifecycle = require("codediff.ui.lifecycle")
  local tab = vim.api.nvim_get_current_tabpage()
  local session = lifecycle.get_session(tab)
  if not session or session.mode ~= "history" then return nil end
  local history = lifecycle.get_explorer(tab)
  if not history then return nil end
  ensure_hooks(history)
  return history, tab
end

-- Commit and file path of a history row. The path is nil for a commit row
-- of a whole-repository history.
local function row_entry(history, line)
  local node = history.tree:get_node(line)
  local data = node and node.data
  if not data then return nil end
  if data.type == "file" then
    return { id = node:get_id(), hash = data.commit_hash, path = data.path }
  elseif data.type == "commit" then
    local path = history.is_single_file_mode and (data.file_path or history.opts.file_path) or nil
    return { id = node:get_id(), hash = data.hash, path = path }
  end
end

local function is_ancestor(git_root, a, b)
  local res = vim.system({ "git", "merge-base", "--is-ancestor", a, b }, { cwd = git_root }):wait()
  return res.code == 0
end

-- `whole` compares the full commits; otherwise only the file of the rows.
local function compare(history, tab, a, b, whole)
  if not a or not b then
    vim.notify("codediff: pick commit or file rows", vim.log.levels.WARN)
    return
  end
  if a.hash == b.hash then
    vim.notify("codediff: both rows are the same commit", vim.log.levels.WARN)
    return
  end
  local old, new = a, b
  if is_ancestor(history.git_root, b.hash, a.hash) then old, new = b, a end

  local path_old, path_new = old.path or new.path, new.path or old.path
  if not whole and not path_old then
    vim.notify("codediff: no file on these rows; pick file rows or use c", vim.log.levels.WARN)
    return
  end

  local state = panels[history]
  state.old, state.new, state.mark = old, new, nil
  paint(history)

  if whole then
    vim.cmd(("CodeDiff %s %s"):format(old.hash, new.hash))
    return
  end

  require("codediff.ui.view").update(tab, {
    mode = "history",
    git_root = history.git_root,
    original_path = path_old,
    modified_path = path_new,
    original_revision = old.hash,
    modified_revision = new.hash,
    line_range = history.opts.line_range,
  }, require("codediff.config").options.diff.jump_to_first_change)
end

local function bind_compare(buf)
  local function mark()
    local history = history_panel()
    if not history then return end
    local entry = row_entry(history, vim.fn.line("."))
    if not entry then
      vim.notify("codediff: not a commit or file row", vim.log.levels.WARN)
      return
    end
    panels[history].mark = entry
    paint(history)
  end

  local function compare_with_mark(whole)
    return function()
      local history, tab = history_panel()
      if not history then return end
      local marked = panels[history].mark
      if not marked then
        vim.notify("codediff: mark a row with m first", vim.log.levels.WARN)
        return
      end
      compare(history, tab, marked, row_entry(history, vim.fn.line(".")), whole)
    end
  end

  local function compare_selection(whole)
    return function()
      local first, last = vim.fn.line("v"), vim.fn.line(".")
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
      local history, tab = history_panel()
      if not history then return end
      compare(history, tab, row_entry(history, first), row_entry(history, last), whole)
    end
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  local function map(mode, lhs, fn, desc)
    vim.keymap.set(mode, lhs, fn, vim.tbl_extend("force", opts, { desc = desc }))
  end
  map("n", "m", mark, compare_keys[1][2])
  map("n", "d", compare_with_mark(false), compare_keys[2][2])
  map("x", "d", compare_selection(false), compare_keys[2][2])
  map("n", "c", compare_with_mark(true), compare_keys[3][2])
  map("x", "c", compare_selection(true), compare_keys[3][2])
end

-- codediff puts its tab-wide keys on the history panel too, re-applying them
-- on every diff update. Its do/dp there make `d` wait for a second key, and
-- they have nothing to act on in the panel.
local function drop_diff_keys_from_panel()
  local lifecycle = require("codediff.ui.lifecycle")
  local set_tab_keymap = lifecycle.set_tab_keymap
  lifecycle.set_tab_keymap = function(tabpage, mode, lhs, ...)
    local ok = set_tab_keymap(tabpage, mode, lhs, ...)
    local view_keys = require("codediff.config").options.keymaps.view
    local session = lifecycle.get_session(tabpage)
    if mode == "n" and (lhs == view_keys.diff_get or lhs == view_keys.diff_put)
      and session and session.mode == "history"
      and session.explorer and vim.api.nvim_buf_is_valid(session.explorer.bufnr) then
      pcall(vim.keymap.del, "n", lhs, { buffer = session.explorer.bufnr })
    end
    return ok
  end
end

-- g? help: codediff builds its sections from a fixed list, so the compare
-- keys are appended to the open help window afterwards.
local function extend_help()
  local help = require("codediff.ui.keymap_help")
  local toggle_help = help.toggle
  help.toggle = function(tabpage)
    toggle_help(tabpage)
    local session = require("codediff.ui.lifecycle").get_session(tabpage)
    local win = session and session._help_win
    if not session or session.mode ~= "history" or not win or not vim.api.nvim_win_is_valid(win) then return end

    local hbuf = vim.api.nvim_win_get_buf(win)
    local width = vim.api.nvim_win_get_width(win)
    local title = "COMPARE"
    local lines = { "", string.rep(" ", math.floor((width - #title) / 2)) .. title }
    for _, k in ipairs(compare_keys) do
      lines[#lines + 1] = ("%14s → %s"):format(k[1], k[2])
    end
    local start = vim.api.nvim_buf_line_count(hbuf)
    vim.bo[hbuf].modifiable = true
    vim.api.nvim_buf_set_lines(hbuf, -1, -1, false, lines)
    vim.bo[hbuf].modifiable = false

    local ns = vim.api.nvim_create_namespace("codediff-help")
    local function hl(row, from, to, group)
      vim.api.nvim_buf_set_extmark(hbuf, ns, row, from, { end_col = to, hl_group = group })
    end
    hl(start + 1, 0, #lines[2], "CodeDiffHelpSection")
    for i = 3, #lines do
      hl(start + i - 1, 0, 14, "CodeDiffHelpKey")
      hl(start + i - 1, 14, #lines[i], "CodeDiffHelpDesc")
    end

    local max = width
    for _, l in ipairs(lines) do max = math.max(max, vim.fn.strdisplaywidth(l) + 3) end
    local height = vim.api.nvim_buf_line_count(hbuf)
    vim.api.nvim_win_set_config(win, {
      relative = "editor",
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - max) / 2),
      width = max,
      height = height,
    })
  end
end

function M.setup()
  drop_diff_keys_from_panel()
  extend_help()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CodeDiffHistoryCompare", { clear = true }),
    pattern = "codediff-history",
    callback = function(args) bind_compare(args.buf) end,
  })
end

return M
