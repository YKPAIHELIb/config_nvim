-- Per-line git blame with stack-based drill-down.
-- <Tab> on a commit reblames at its parent (push); <BS> pops back up.
-- Complements codediff.nvim which handles diff/staging/conflicts but not blame.

-- Open `git show <hash>` in a centered floating window. Used as the
-- commit_detail_view callback so <CR> doesn't disturb the blame+file layout.
-- Built-in "tab"/"split"/"vsplit"/"current" all rearrange windows; "vsplit"
-- additionally triggers a BufHidden race in blame.nvim's stack view.
local function show_commit_floating(commit_hash, _row, file_path)
  require("config.git_float").show_commit(vim.fn.fnamemodify(file_path, ":h"), commit_hash)
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

-- File on disk behind `win`, and whether `win` shows that file's lines.
-- A codediff pane resolves through its session: virtual (git revision) panes
-- map to the tracked path, and the explorer maps to the modified side.
local function file_for(win)
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

local function close_blame_tab(tab)
  if not vim.api.nvim_tabpage_is_valid(tab) then return end
  if #vim.api.nvim_list_tabpages() == 1 then
    vim.t[tab].tool_tab, vim.t[tab].blame_file, vim.t[tab].blame_win = nil, nil, nil
    return
  end
  pcall(vim.cmd, vim.api.nvim_tabpage_get_number(tab) .. "tabclose")
end

-- Every blame gets its own tab holding the file and its blame window, so any
-- number of blames (and the codediffs opened from them with `d`) coexist.
-- Inside a blame tab the same key closes it.
local function blame_in_tab()
  if vim.t.blame_file then
    close_blame_tab(vim.api.nvim_get_current_tabpage())
    return
  end
  local win = vim.api.nvim_get_current_win()
  local path, has_lines = file_for(win)
  if not path or vim.fn.filereadable(path) == 0 then
    vim.notify("blame: no file on disk for this window", vim.log.levels.WARN)
    return
  end
  local line = has_lines and vim.api.nvim_win_get_cursor(win)[1] or 1

  vim.cmd("tabnew " .. vim.fn.fnameescape(path))
  vim.t.tool_tab = true
  vim.t.blame_file = path
  pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  -- BlameToggle closes whichever blame it opened last; forgetting it makes
  -- the command always open a new one.
  require("blame").last_opened_view = nil
  vim.cmd("BlameToggle")
end

return {
  "FabijanZulj/blame.nvim",
  cmd = { "BlameToggle" },
  keys = {
    { "<leader>wb", blame_in_tab, desc = "Git blame (own tab)" },
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

    -- Closing the blame window (q / <Esc>) closes its tab. BlameViewOpened
    -- fires with the new blame window current.
    local tab_group = vim.api.nvim_create_augroup("BlameTab", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = tab_group,
      pattern = "BlameViewOpened",
      callback = function()
        if vim.t.blame_file then vim.t.blame_win = vim.api.nvim_get_current_win() end
      end,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
      group = tab_group,
      callback = function(args)
        local win = tonumber(args.match)
        if not win or not vim.api.nvim_win_is_valid(win) then return end
        local tab = vim.api.nvim_win_get_tabpage(win)
        if vim.t[tab].blame_win ~= win then return end
        vim.schedule(function() close_blame_tab(tab) end)
      end,
    })
  end,
}
