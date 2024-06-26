local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

keymap("n", "<leader>e", "<cmd>lua MiniFiles.open()<CR>", opts)
keymap("n", "<leader>E", "<cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
-- keymap("n", "<S-l>", ":bnext<CR>", opts)
-- keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
-- keymap("n", "<A-j>", ":m .+1<CR>==", opts)
-- keymap("n", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- Visual Block --
-- Move text up and down
-- keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
-- keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Remove search highlight on Esc button
keymap("n", "<Esc>", ":noh<CR><Esc>", opts)

-- Search and replace remaps
keymap("n", "<leader>/", ':let @x=@"<CR>"zyiw:let @"=@x<CR>/<C-R>z<CR>', opts)
keymap("v", "<leader>/", '<ESC>:let @x=@"<CR>gv"zy:let @"=@x<CR>/<C-R>z<CR>', opts)
keymap("n", "<leader>?", ':let @x=@"<CR>"zyiw:let @"=@x<CR>:.,$s/<C-R>z//gc<LEFT><LEFT><LEFT>', opts)
keymap("v", "<leader>?", '<ESC>:let @x=@"<CR>gv"zy:let @"=@x<CR>:.,$s/<C-R>z//gc<LEFT><LEFT><LEFT>', opts)

-- Keep search results in the center of the screen
keymap("n", "n", "nzz", opts)
keymap("n", "N", "Nzz", opts)

-- Paste/delete without yank
keymap("v", "p", 'p:let @"=@0<CR>', opts)
keymap("n", "x", '"_x', opts)
keymap("n", "X", '"_X', opts)
keymap("v", "x", '"_x', opts)
keymap("v", "X", '"_X', opts)

-- H/L is more natural than g_/$
keymap("n", "H", '^', opts)
keymap("v", "H", '^', opts)
keymap("n", "L", '$', opts)
keymap("v", "L", '$', opts)

-- Copy line without CR
keymap("n", "Y", '^y$', opts)

-- Ctrl+Backspace for delete word in insert mode
keymap("i", "<M-BS>", '<C-w>', opts)

local telescope_status_ok, telescope_builtin = pcall(require, 'telescope.builtin')
if not telescope_status_ok then
  return
end

vim.keymap.set('n', '<leader>sf', telescope_builtin.find_files, {})
vim.keymap.set('n', '<leader>sg', telescope_builtin.git_files, {})
vim.keymap.set('n', '<leader>sr', telescope_builtin.live_grep, {})
vim.keymap.set('n', '<leader>sb', telescope_builtin.buffers, {})
vim.keymap.set('n', '<leader>sh', telescope_builtin.help_tags, {})
vim.keymap.set('n', '<leader>st', telescope_builtin.lsp_workspace_symbols, {})

