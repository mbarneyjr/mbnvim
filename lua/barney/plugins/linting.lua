local lint = require("lint")
local key = require("barney.lib.keymap")

-- define github actions file type
lint.linters_by_ft = {
  ["yaml.github_actions"] = { "actionlint" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

local try_lint = function()
  lint.try_lint()
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = lint_augroup,
  callback = try_lint,
})

vim.api.nvim_create_user_command("Lint", try_lint, { desc = "Lint the current buffer" })
key.nmap("<leader>l", try_lint, "[l]int")
