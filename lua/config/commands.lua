-- General-purpose user commands that aren't tied to a specific plugin.
-- Plugin-specific commands belong in the plugin's spec file.

-- :MessagesPrint — dump the message history (everything :messages would show,
-- including errors that scrolled off) into a scratch split, so you can search,
-- yank, or copy.
vim.api.nvim_create_user_command("MessagesPrint", function()
  local output = vim.fn.execute("messages")
  vim.cmd("new")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(output, "\n"))
end, { desc = "Dump :messages into a scratch buffer" })

local function yank_to_clipboard(value)
  vim.fn.setreg("+", value)
  vim.notify("Yanked: " .. value)
end

vim.api.nvim_create_user_command("YankPath", function()
  yank_to_clipboard(vim.fn.expand("%:p"))
end, { desc = "Yank absolute path of current buffer to system clipboard" })

vim.api.nvim_create_user_command("YankRelPath", function()
  yank_to_clipboard(vim.fn.expand("%"))
end, { desc = "Yank cwd-relative path of current buffer to system clipboard" })

vim.api.nvim_create_user_command("YankFilename", function()
  yank_to_clipboard(vim.fn.expand("%:t"))
end, { desc = "Yank filename of current buffer to system clipboard" })
