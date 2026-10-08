-- Runs a :CodeDiff command so its diff opens in a new tab. :CodeDiff run from
-- a codediff tab closes that tab, so the command is issued from a scratch tab
-- that is dropped once the new diff tab opens.
return function(cmd)
  vim.cmd("tabnew")
  local scratch = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeDiffOpen",
    once = true,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_tabpage_is_valid(scratch) then
          pcall(vim.cmd, vim.api.nvim_tabpage_get_number(scratch) .. "tabclose")
        end
      end)
    end,
  })
  vim.cmd(cmd)
end
