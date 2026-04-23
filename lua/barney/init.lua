-- Auto-detect large repos so plugins can disable expensive features
vim.g.large_repo = false
local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
if git_dir ~= "" then
  local result = vim.fn.system("git ls-files | wc -l")
  local file_count = tonumber(vim.trim(result)) or 0
  vim.g.large_repo = file_count > 10000
end
if vim.g.large_repo then
  vim.print("Large repository detected. Some plugins may be disabled or configured differently for better performance.")
end

require("barney.core")
require("barney.plugins")
