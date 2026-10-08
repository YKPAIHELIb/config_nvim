-- Centered floating windows for git output. q / <Esc> close a float without
-- touching the window layout behind it.
local M = {}

local ns = vim.api.nvim_create_namespace("git-float")

-- Opens `lines` in a float and returns its buffer and window. Options:
--   title       window title
--   filetype    buffer filetype
--   highlights  list of { row, start_col, end_col, group } (0-based, bytes)
--   fit         window height follows the line count
function M.open(lines, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  if opts.filetype then vim.bo[buf].filetype = opts.filetype end
  for _, h in ipairs(opts.highlights or {}) do
    vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  if opts.fit then height = math.max(1, math.min(height, #lines)) end
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. (opts.title or "git") .. " ",
    title_pos = "center",
  })

  local close = function() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q",     close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
  return buf, win
end

-- `git show <rev>` run in `dir`.
function M.show_commit(dir, rev, title)
  local output = vim.fn.systemlist({ "git", "-C", dir, "show", rev })
  if vim.v.shell_error ~= 0 then
    vim.notify("git show failed: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    return
  end
  M.open(output, { title = title or rev:sub(1, 12), filetype = "git" })
end

return M
