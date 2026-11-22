-- Mouse-wheel scrolling that keeps codediff's two panes aligned.
--
-- codediff internals used: codediff.ui.lifecycle (get_session, get_windows)
-- and its User CodeDiffOpen event payload (data.tabpage).
--
-- codediff 4 went back to native scrollbind and relies on a Neovim fix for
-- tall virt_lines (neovim PR #41519); it has no wheel handling of its own.
--
-- Mouse-wheel bypasses vim's scrollbind sync because codediff aligns panes
-- with virt_lines extmarks (visual-only) while scrollbind counts real
-- buffer lines. Per-buffer <ScrollWheelUp/Down> maps do the scroll then
-- :syncbind on the pane under the mouse. Keyboard scrolls, edits, and
-- codediff's own hunk-navigation reflows aren't touched.
--
-- Buffer-local mouse maps are looked up in the *current* buffer, not the
-- one under the mouse, so every buffer in the codediff tab gets the map
-- (e.g. wheeling over a pane while the explorer has focus). Only panes
-- get :syncbind; other windows just scroll.
local M = {}

local function is_pane(winid)
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then return false end
  local orig_win, mod_win = lifecycle.get_windows(vim.api.nvim_win_get_tabpage(winid))
  return winid == orig_win or winid == mod_win
end

local function wheel_lines()
  return tonumber(vim.o.mousescroll:match("ver:(%d+)")) or 3
end

local function wheel_sync(ctrl_key)
  return function()
    local pos = vim.fn.getmousepos()
    local winid = pos and pos.winid or 0
    if winid == 0 or not vim.api.nvim_win_is_valid(winid) then
      winid = vim.api.nvim_get_current_win()
    end
    local lines = wheel_lines()
    if lines == 0 then return end
    pcall(vim.api.nvim_win_call, winid, function()
      vim.cmd("normal! " .. lines .. ctrl_key)
      if is_pane(winid) then vim.cmd("syncbind") end
    end)
  end
end

local function bind_wheel(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.b[bufnr].codediff_wheel_bound then return end
  vim.b[bufnr].codediff_wheel_bound = true
  vim.keymap.set("n", "<ScrollWheelUp>",   wheel_sync("\25"), { buffer = bufnr, silent = true })
  vim.keymap.set("n", "<ScrollWheelDown>", wheel_sync("\5"),  { buffer = bufnr, silent = true })
end

local function bind_tab(tabpage)
  if not vim.api.nvim_tabpage_is_valid(tabpage) then return end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    bind_wheel(vim.api.nvim_win_get_buf(win))
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("CodeDiffWheelSync", { clear = true })

  -- CodeDiffOpen fires synchronously at the end of the plugin's create(),
  -- but the lifecycle session is populated inside a vim.schedule callback
  -- that hasn't run yet. Deferring with vim.schedule queues this after
  -- render_everything, so get_windows() sees a real session.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function(args)
      local tabpage = args.data and args.data.tabpage
      if not tabpage then return end
      vim.schedule(function() bind_tab(tabpage) end)
    end,
  })

  -- Explorer-driven buffer swaps: a fresh buffer entering a window of a
  -- codediff tab after the initial open would otherwise have no map.
  -- BufEnter covers panes codediff fills without BufWinEnter (the empty side
  -- of an added or deleted file), so the focused buffer always has the map.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
    group = group,
    callback = function(args)
      local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
      if not ok then return end
      if not lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then return end
      bind_wheel(args.buf)
    end,
  })
end

return M
