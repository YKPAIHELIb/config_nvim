-- The two revisions a codediff tab compares, and views of them: the right
-- commit's details, the log of commits from left to right, and codediff's
-- history panel for that range.
--
-- A `:CodeDiff A B` / `A...B` / `:CodeDiff A` tab has a fixed pair, taken
-- from its explorer, whichever file is shown. Plain `:CodeDiff` compares
-- HEAD with the index and working tree. A history tab and a single-file
-- diff use the pair currently shown. A merge conflict's ours side is HEAD
-- and its theirs side is the commit being merged, cherry-picked, reverted
-- or rebased.
--
-- codediff internals used:
--   codediff.ui.lifecycle   get_session: mode, git_root, original_revision,
--                           modified_revision, explorer
--   explorer object         base_revision, target_revision
local M = {}

local git_float = require("config.git_float")

local function git(root, args)
  local res = vim.system(vim.list_extend({ "git" }, args), { cwd = root, text = true }):wait()
  return res.code == 0, res.stdout or "", res.stderr or ""
end

-- A codediff revision as a commit-ish. The working tree and the index
-- (nil, "WORKING", ":0") sit on top of HEAD, so they give HEAD and true.
local function commit_of(root, rev)
  if rev == nil or rev == "WORKING" or rev == ":0" then return "HEAD", true end
  if rev == ":2" then return "HEAD" end
  if rev == ":3" then
    for _, ref in ipairs({ "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "REBASE_HEAD" }) do
      if git(root, { "rev-parse", "-q", "--verify", ref }) then return ref end
    end
    return nil
  end
  return rev
end

-- { root, left, right, worktree } for the current tab, or nil after a
-- warning. `worktree` is set when the right side is the working tree or
-- index, `right` then being HEAD.
local function current_pair()
  local session = require("codediff.ui.lifecycle").get_session(vim.api.nvim_get_current_tabpage())
  local function warn(msg)
    vim.notify("codediff: " .. msg, vim.log.levels.WARN)
  end
  if not session then return warn("not a codediff tab") end
  local root = session.git_root
  if not root then return warn("this tab compares files, not git revisions") end

  local left, right
  if session.mode == "explorer" then
    local explorer = session.explorer or {}
    left, right = explorer.base_revision or "HEAD", explorer.target_revision
  else
    if session.mode == "history" and not session.modified_revision then
      return warn("select a commit in the history panel")
    end
    left, right = session.original_revision, session.modified_revision
  end

  local right_commit, worktree = commit_of(root, right)
  left = commit_of(root, left)
  if not left or not right_commit then return warn("no commit for a side of this conflict") end
  return { root = root, left = left, right = right_commit, worktree = worktree }
end

-- Full hashes shortened, names (HEAD, MERGE_HEAD) and suffixes (^) kept.
local function label(rev)
  local hex, rest = rev:match("^(%x+)(.*)$")
  if hex and #hex > 12 then return hex:sub(1, 8) .. rest end
  return rev
end

local function range_label(p)
  return label(p.left) .. ".." .. label(p.right) .. (p.worktree and " + working tree" or "")
end

function M.info()
  local p = current_pair()
  if not p then return end
  git_float.show_commit(p.root, p.right, label(p.right) .. (p.worktree and " (working tree on top)" or ""))
end

-- One `git log --graph` line per row in the user's lg1 layout:
-- hash - (relative date) subject - author (refs).
local log_format = "--format=format:%h%x1f%ar%x1f%s%x1f%an%x1f%d"
local log_hl = { hash = "Identifier", date = "String", author = "Comment", refs = "WarningMsg" }

function M.log()
  local p = current_pair()
  if not p then return end
  local range = p.left .. ".." .. p.right
  local ok, out, err = git(p.root, { "log", "--graph", "--decorate", log_format, range })
  if not ok then
    vim.notify("git log failed: " .. err, vim.log.levels.ERROR)
    return
  end
  if out == "" then
    vim.notify("codediff: no commits in " .. range_label(p), vim.log.levels.INFO)
    return
  end

  local lines, highlights, hashes = {}, {}, {}
  for raw in vim.gsplit(out, "\n", { plain = true }) do
    local row = #lines
    -- Graph characters contain no hex digits, so the first hex run is the hash.
    local graph, fields = raw:match("^([^%x]*)(%x+\31.*)$")
    if not graph then
      lines[#lines + 1] = raw
    else
      local hash, date, subject, author, refs = unpack(vim.split(fields, "\31", { plain = true }))
      local line = graph
      local function add(text, group)
        if group and text ~= "" then
          highlights[#highlights + 1] = { row, #line, #line + #text, group }
        end
        line = line .. text
      end
      add(hash, log_hl.hash)
      add(" - ")
      add("(" .. date .. ")", log_hl.date)
      add(" " .. subject)
      add(" - " .. author, log_hl.author)
      add(refs or "", log_hl.refs)
      lines[#lines + 1] = line
      hashes[row + 1] = hash
    end
  end

  local buf, win = git_float.open(lines, { title = "log " .. range_label(p), highlights = highlights, fit = true })
  vim.wo[win].cursorline = true

  local function hash_here()
    local hash = hashes[vim.api.nvim_win_get_cursor(win)[1]]
    if not hash then vim.notify("codediff: no commit on this line", vim.log.levels.WARN) end
    return hash
  end
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
  end
  map("<CR>", function()
    local hash = hash_here()
    if hash then git_float.show_commit(p.root, hash) end
  end, "Commit details")
  map("d", function()
    local hash = hash_here()
    if not hash then return end
    pcall(vim.api.nvim_win_close, win, true)
    vim.cmd(("CodeDiff %s^ %s"):format(hash, hash))
  end, "CodeDiff for this commit")
end

function M.history()
  local p = current_pair()
  if not p then return end
  local range = p.left .. ".." .. p.right
  local ok, count = git(p.root, { "rev-list", "--count", range })
  if ok and tonumber(count) == 0 then
    vim.notify("codediff: no commits in " .. range_label(p), vim.log.levels.INFO)
    return
  end
  vim.cmd("CodeDiff history " .. range)
end

return M
