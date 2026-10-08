-- Wraps a sorter so "/" and "\" match each other in both prompt and entries.
local function slash_agnostic(sorter)
  local score, highlight = sorter.scoring_function, sorter.highlighter
  local function norm(s)
    return type(s) == "string" and (s:gsub("\\", "/")) or s
  end
  sorter.scoring_function = function(self, prompt, line, ...)
    return score(self, norm(prompt), norm(line), ...)
  end
  sorter.highlighter = function(self, prompt, display)
    return highlight(self, norm(prompt), norm(display))
  end
  return sorter
end

local function path_sorter(opts)
  return slash_agnostic(require("telescope.sorters").get_fzy_sorter(opts))
end

-- Opens a builtin picker. From visual mode the prompt starts with the
-- selected text, or empty when the selection spans several lines.
local function picker(name, base_opts)
  return function()
    local opts = base_opts and base_opts() or {}
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
      local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
      opts.default_text = #lines == 1 and lines[1] or ""
    end
    require("telescope.builtin")[name](opts)
  end
end

local nx = { "n", "x" }

-- ripgrep skips hidden (dot) paths and gitignored paths by default. These
-- include hidden paths but never descend into .git itself; `everything`
-- also includes gitignored paths.
local function rg_flags(everything)
  local flags = { "--hidden", "--glob", "!**/.git/*" }
  if everything then flags[#flags + 1] = "--no-ignore" end
  return flags
end

local function files_opts(everything)
  return function()
    return { find_command = vim.list_extend({ "rg", "--files", "--color", "never" }, rg_flags(everything)) }
  end
end

local function grep_opts(everything)
  return function()
    return { additional_args = rg_flags(everything) }
  end
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  keys = {
    { "<leader>sf", picker("find_files", files_opts(false)), mode = nx, desc = "Find Files" },
    { "<leader>sF", picker("find_files", files_opts(true)), mode = nx, desc = "Find Files (incl. ignored)" },
    { "<leader>sg", picker("git_files"), mode = nx, desc = "Git Files" },
    { "<leader>sr", picker("live_grep", grep_opts(false)), mode = nx, desc = "Live Grep" },
    { "<leader>sR", picker("live_grep", grep_opts(true)), mode = nx, desc = "Live Grep (incl. ignored)" },
    { "<leader>sb", picker("buffers", function() return { sorter = path_sorter({}) } end), mode = nx, desc = "Buffers" },
    { "<leader>sh", picker("help_tags"), mode = nx, desc = "Help Tags" },
    { "<leader>sk", picker("keymaps"), mode = nx, desc = "Keymaps" },
    -- The stock commands picker matches the command name only; matching the
    -- description too finds commands by what they do.
    {
      "<leader>sc",
      picker("commands", function()
        local by_name = require("telescope.make_entry").gen_from_commands({})
        return {
          entry_maker = function(cmd)
            local entry = by_name(cmd)
            entry.ordinal = cmd.name .. " " .. (cmd.definition or "")
            return entry
          end,
        }
      end),
      mode = nx,
      desc = "Commands",
    },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        -- "ascending" puts the prompt on top and results below in normal order.
        -- Also avoids an upstream bug in pickers.lua:1466 where the "descending"
        -- code path tries to set the cursor past the end of the results buffer
        -- during rapid filtering (causes "Invalid cursor line: out of range").
        sorting_strategy = "ascending",
        file_sorter = path_sorter,
        layout_config = {
          prompt_position = "top",
        },
        -- Used by every file-opening action (<CR>, <C-t>, <C-v>, <C-x>).
        get_selection_window = function()
          return require("config.tabs").target_win(vim.api.nvim_get_current_win())
        end,
      },
    })

    -- <leader>st / <leader>sm work only with LSP; attached lazily on LspAttach
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        vim.keymap.set(nx, "<leader>st", picker("lsp_workspace_symbols"),
          { buffer = args.buf, desc = "Workspace Symbols (LSP)" })
        vim.keymap.set(nx, "<leader>sm", picker("lsp_document_symbols"),
          { buffer = args.buf, desc = "Document Symbols / Members (LSP)" })
      end,
    })
  end,
}
