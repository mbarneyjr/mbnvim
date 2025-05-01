vim.g.skip_ts_context_commentstring_module = true
-- import comment plugin safely
local comment = require("Comment")

local ts_context_commentstring = require("ts_context_commentstring")
local comment_nvim_integration = require("ts_context_commentstring.integrations.comment_nvim")

ts_context_commentstring.setup({
  enable_autocmd = true,
})

comment.setup({
  pre_hook = comment_nvim_integration.create_pre_hook(),
})
