return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  config = function()
    vim.g.skip_ts_context_commentstring_module = true
    -- import comment plugin safely
    local comment = require("Comment")

    local ts_context_commentstring = require("ts_context_commentstring")

    ts_context_commentstring.setup({
      enable_autocmd = true,
    })

    comment.setup({
      pre_hook = function()
        return vim.bo.commentstring
      end,
    })
  end,
}
