-- True when Neovim runs inside Termux (Android). Same check as codediff's
-- installer: Termux sets TERMUX_VERSION, and its PREFIX is under the app's
-- data directory.
local prefix = vim.env.PREFIX or ""
return (vim.env.TERMUX_VERSION or "") ~= "" or prefix:match("^/data/data/com%.termux") ~= nil
