local opt = vim.opt

opt.clipboard = "unnamedplus"               -- allows neovim to access the system clipboard
opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
opt.fileencoding = "utf-8"                  -- the encoding written to a file
opt.incsearch = true                        -- highlight matches as typing search phrase
opt.hlsearch = true                         -- highlight all matches on previous search pattern
opt.ignorecase = true                       -- ignore case in search patterns
opt.mouse = "a"                             -- allow the mouse to be used in neovim
opt.pumheight = 10                          -- pop up menu height
opt.showtabline = 2                         -- always show tabs
opt.smartcase = true                        -- smart case
opt.smartindent = true                      -- make indenting smarter again
opt.splitbelow = true                       -- force all horizontal splits to go below current window
opt.splitright = true                       -- force all vertical splits to go to the right of current window
opt.swapfile = false                        -- creates a swapfile
opt.termguicolors = true                    -- set term gui colors (most terminals support this)
opt.timeoutlen = 1000                       -- time to wait for a mapped sequence to complete (in milliseconds)
opt.undofile = false                         -- enable persistent undo
opt.updatetime = 300                        -- faster completion (4000ms default)
opt.expandtab = true                        -- convert tabs to spaces
opt.shiftwidth = 4                          -- the number of spaces inserted for each indentation
opt.tabstop = 4                             -- insert 2 spaces for a tab
opt.cursorline = true                       -- highlight the current line
opt.number = true                           -- set numbered lines
opt.relativenumber = true                   -- set relative numbered lines
opt.numberwidth = 4                         -- set number column width to 2 {default 4}
opt.signcolumn = "yes"                      -- always show the sign column, otherwise it would shift the text each time
opt.wrap = false                            -- display lines as one long line
opt.scrolloff = 5                           -- is one of my fav
opt.sidescrolloff = 8

vim.cmd "set whichwrap+=<,>,[,],h,l"

if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    vim.o.shell = 'powershell'
end

