-- Routing of "open a file" actions away from tool tabs.
--
-- A tool tab holds a codediff session or has no regular file window at all
-- (terminal, help, quickfix, ...). Files opened from a tool tab, or from a
-- non-file window such as a terminal split, land in a file window of the
-- current or most recently visited editing tab.
local M = {}

local visit = 0
vim.api.nvim_create_autocmd("TabEnter", {
  group = vim.api.nvim_create_augroup("EditingTabTracker", { clear = true }),
  callback = function()
    visit = visit + 1
    vim.t.last_visit = visit
  end,
})

local function is_file_win(win)
  return vim.api.nvim_win_get_config(win).relative == ""
    and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

-- Checked via package.loaded so a lookup never triggers lazy-loading codediff.
local function is_codediff_tab(tab)
  local lifecycle = package.loaded["codediff.ui.lifecycle"]
  return lifecycle ~= nil and lifecycle.get_session(tab) ~= nil
end

local function file_win_of(tab)
  if is_codediff_tab(tab) then return nil end
  local cur = vim.api.nvim_tabpage_get_win(tab)
  if is_file_win(cur) then return cur end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if is_file_win(win) then return win end
  end
end

-- Window a file picked from `win` should open in, or nil when no editing tab
-- exists.
local function find_target(win)
  local tab = vim.api.nvim_win_get_tabpage(win)
  if is_file_win(win) and not is_codediff_tab(tab) then return win end

  local best = file_win_of(tab)
  if best then return best end

  local best_visit = -1
  for _, t in ipairs(vim.api.nvim_list_tabpages()) do
    if t ~= tab then
      local candidate = file_win_of(t)
      local last = vim.t[t].last_visit or 0
      if candidate and last > best_visit then
        best, best_visit = candidate, last
      end
    end
  end
  return best
end

function M.is_redirected(win)
  win = win or vim.api.nvim_get_current_win()
  return find_target(win) ~= win
end

-- Like find_target, but opens a new tab when no editing tab exists.
function M.target_win(win)
  win = win or vim.api.nvim_get_current_win()
  local target = find_target(win)
  if target then return target end
  vim.cmd("tabnew")
  return vim.api.nvim_get_current_win()
end

local function jump_to(win, item)
  local b = item.bufnr or vim.fn.bufadd(item.filename)
  vim.api.nvim_set_current_win(win)
  vim.cmd("normal! m'")
  vim.bo[b].buflisted = true
  vim.api.nvim_win_set_buf(win, b)
  vim.api.nvim_win_set_cursor(win, { item.lnum, item.col - 1 })
  vim.cmd("normal! zv")
end

-- `on_list` handler for vim.lsp.buf.* location requests made from `win`.
-- Locations all inside the current buffer stay in `win` (a single one is
-- jumped to, several go to the quickfix list); anything touching another
-- file goes to the editing tab. `always_list` skips the single-result jump,
-- matching vim.lsp.buf.references.
function M.location_handler(win, always_list)
  return function(list)
    local cur = list.context.bufnr
    local local_only = true
    for _, item in ipairs(list.items) do
      if (item.bufnr or vim.fn.bufadd(item.filename)) ~= cur then
        local_only = false
        break
      end
    end

    local target = local_only and win or M.target_win(win)
    if #list.items == 1 and not always_list then
      jump_to(target, list.items[1])
      return
    end
    vim.api.nvim_set_current_win(target)
    vim.fn.setqflist({}, " ", list)
    vim.cmd("botright copen")
  end
end

return M
