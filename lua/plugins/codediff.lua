-- VSCode-style side-by-side diff. Lazy-loaded on :CodeDiff so it stays free
-- for `git difftool` and ad-hoc CLI compares (`nvim +"CodeDiff file a b"`).
-- The plugin auto-downloads a prebuilt C binary; no compiler needed.
return {
  "esmuellert/codediff.nvim",
  cmd = { "CodeDiff", "CodeDiffScratch", "CodeDiffToggleWS" },
  config = function()
    -- VSCode Dark+-ish diff colors. Defined as dedicated groups so they don't
    -- bleed into nvim's general DiffAdd/DiffDelete (used by :diffthis, gitsigns, etc.).
    -- The line_* groups paint whole changed lines; the char_* groups paint the
    -- actual differing characters within those lines (brighter for contrast).
    vim.api.nvim_set_hl(0, "CodeDiffLineDelete", { bg = "#3F1F1F" })
    vim.api.nvim_set_hl(0, "CodeDiffLineInsert", { bg = "#1E3A1E" })
    vim.api.nvim_set_hl(0, "CodeDiffCharDelete", { bg = "#5A2929" })
    vim.api.nvim_set_hl(0, "CodeDiffCharInsert", { bg = "#2E5A2E" })

    local highlights = {
      line_delete = "CodeDiffLineDelete",
      line_insert = "CodeDiffLineInsert",
      char_delete = "CodeDiffCharDelete",
      char_insert = "CodeDiffCharInsert",
    }
    local ignore_ws = true -- matches VSCode's default; treats indent-only shifts as unchanged

    local function apply()
      require("codediff").setup({
        highlights = highlights,
        diff = {
          layout = "side-by-side",
          ignore_trim_whitespace = ignore_ws,
        },
        explorer = {
          view_mode = "tree",
        },
        history = {
          view_mode = "tree",
        },
      })
    end
    apply()

    -- :CodeDiffToggleWS — flip whitespace sensitivity. Re-run your :CodeDiff command
    -- after toggling for the change to show in an already-open session.
    vim.api.nvim_create_user_command("CodeDiffToggleWS", function()
      ignore_ws = not ignore_ws
      apply()
      vim.notify("CodeDiff: ignore_trim_whitespace = " .. tostring(ignore_ws), vim.log.levels.INFO)
    end, { desc = "Toggle CodeDiff's ignore_trim_whitespace setting" })

    -- :CodeDiffScratch [ext] — open a fresh side-by-side canvas backed by two empty temp files.
    -- Diff updates live as you paste/type. Optional arg sets the file extension for syntax highlighting.
    vim.api.nvim_create_user_command("CodeDiffScratch", function(opts)
      local ext = opts.args ~= "" and opts.args or "txt"
      local left  = vim.fn.tempname() .. "." .. ext
      local right = vim.fn.tempname() .. "." .. ext
      vim.fn.writefile({}, left)
      vim.fn.writefile({}, right)
      vim.cmd(string.format("CodeDiff file %s %s", left, right))
    end, {
      nargs = "?",
      desc = "Open CodeDiff with two empty scratch files (optional file extension)",
    })

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

    local wheel_group = vim.api.nvim_create_augroup("CodeDiffWheelSync", { clear = true })

    -- CodeDiffOpen fires synchronously at the end of the plugin's create(),
    -- but the lifecycle session is populated inside a vim.schedule callback
    -- that hasn't run yet. Deferring with vim.schedule queues this after
    -- render_everything, so get_windows() sees a real session.
    vim.api.nvim_create_autocmd("User", {
      group = wheel_group,
      pattern = "CodeDiffOpen",
      callback = function(args)
        local tabpage = args.data and args.data.tabpage
        if not tabpage then return end
        vim.schedule(function() bind_tab(tabpage) end)
      end,
    })

    -- Explorer-driven buffer swaps: a fresh buffer entering a window of a
    -- codediff tab after the initial open would otherwise have no map.
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = wheel_group,
      callback = function(args)
        local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
        if not ok then return end
        if not lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then return end
        bind_wheel(args.buf)
      end,
    })
  end,
}
