-- Per-line git blame with stack-based drill-down.
-- <Tab> on a commit reblames at its parent (push); <BS> pops back up.
-- Complements codediff.nvim which handles diff/staging/conflicts but not blame.

-- Open `git show <hash>` in a centered floating window. Used as the
-- commit_detail_view callback so <CR> doesn't disturb the blame+file layout.
-- Built-in "tab"/"split"/"vsplit"/"current" all rearrange windows; "vsplit"
-- additionally triggers a BufHidden race in blame.nvim's stack view.
local function show_commit_floating(commit_hash, _row, file_path)
  local dir = vim.fn.fnamemodify(file_path, ":h")
  local output = vim.fn.systemlist({ "git", "-C", dir, "show", commit_hash })
  if vim.v.shell_error ~= 0 then
    vim.notify("git show failed: " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  vim.bo[buf].filetype = "git"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. commit_hash:sub(1, 12) .. " ",
    title_pos = "center",
  })

  -- q / <Esc> close the float without touching the blame layout behind it.
  local close = function() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q",     close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
end

-- Inside a blame view, `d` on any line opens codediff for the commit that
-- introduced it (parent..commit range explorer). Complements <CR> (git show
-- float) with a visual side-by-side view. Attached via autocmd because
-- blame.nvim's `mappings` config only exposes named built-in actions and
-- doesn't emit an "on ready" event we could hook.
local function attach_codediff_key(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.b[buf].blame_codediff_bound then return end
  if vim.bo[buf].buftype ~= "nofile" then return end
  local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  -- Fingerprint: blame lines start with a 7+ hex-char short SHA followed by a space.
  -- Tight enough that no other nofile buffer in this config matches.
  if not first_line:match("^%x%x%x%x%x%x%x+%s") then return end
  vim.b[buf].blame_codediff_bound = true

  vim.keymap.set("n", "d", function()
    local hash = vim.api.nvim_get_current_line():match("^(%x+)")
    if not hash then
      vim.notify("blame: no commit hash on this line", vim.log.levels.WARN)
      return
    end
    vim.cmd(("CodeDiff %s^ %s"):format(hash, hash))
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "CodeDiff for commit under cursor",
  })
end

return {
  "FabijanZulj/blame.nvim",
  cmd = { "BlameToggle" },
  keys = {
    { "<leader>wb", "<cmd>BlameToggle<cr>", desc = "Git blame" },
  },
  opts = {
    date_format = "%Y-%m-%d",
    commit_detail_view = show_commit_floating,
  },
  config = function(_, opts)
    require("blame").setup(opts)
    -- CursorMoved fires only after blame.nvim finishes populating the buffer
    -- (BufWinEnter is too early — winfixwidth/content aren't set yet). The
    -- `blame_codediff_bound` guard keeps re-fires cheap.
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = vim.api.nvim_create_augroup("BlameCodeDiffKey", { clear = true }),
      callback = function(args) attach_codediff_key(args.buf) end,
    })
  end,
}
