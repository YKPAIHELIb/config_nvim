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
