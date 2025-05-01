local treesitter = require("nvim-treesitter.configs")
-- configure treesitter
treesitter.setup({ -- enable syntax highlighting
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  },
  highlight = {
    enable = true,
  },
  -- enable indentation
  indent = { enable = true },
  -- enable autotagging (w/ nvim-ts-autotag plugin)
  autotag = {
    enable = true,
  },
  incremental_selection = {
    enable = false,
  },
  playground = {
    enable = true,
  },
})

-- jsdoc indentation workaround
function _G.javascript_indent()
  local line = vim.fn.getline(vim.v.lnum)
  local prev_line = vim.fn.getline(vim.v.lnum - 1)
  if line:match("^%s*[%*/]%s*") then
    if prev_line:match("^%s*%*%s*") then
      return vim.fn.indent(vim.v.lnum - 1)
    end
    if prev_line:match("^%s*/%*%*%s*$") then
      return vim.fn.indent(vim.v.lnum - 1) + 1
    end
  end

  return vim.fn["GetJavascriptIndent"]()
end

vim.cmd([[autocmd FileType javascript setlocal indentexpr=v:lua.javascript_indent()]])
