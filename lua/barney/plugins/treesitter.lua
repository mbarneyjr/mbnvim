local treesitter = require("nvim-treesitter")

treesitter.setup({
  install_dir = vim.fn.stdpath("data") .. "/site/treesitter",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tree-sitter-enable", { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then
      return
    end
    if not vim.list_contains(treesitter.get_available(), lang) then
      return
    end
    treesitter.install(lang):wait(300000)

    if vim.treesitter.query.get(lang, "highlights") then
      vim.treesitter.start(args.buf)
    end

    if vim.treesitter.query.get(lang, "indents") then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    if vim.treesitter.query.get(lang, "folds") then
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end,
})

-- OLD TREESITTER CONFIG
-- local treesitter = require("nvim-treesitter.configs")
-- -- configure treesitter
-- treesitter.setup({ -- enable syntax highlighting
--   context_commentstring = {
--     enable = true,
--     enable_autocmd = false,
--   },
--   highlight = {
--     enable = true,
--   },
--   -- enable indentation
--   indent = { enable = true },
--   -- enable autotagging (w/ nvim-ts-autotag plugin)
--   autotag = {
--     enable = true,
--   },
--   incremental_selection = {
--     enable = false,
--   },
--   playground = {
--     enable = true,
--   },
-- })
--
-- -- jsdoc indentation workaround
-- function _G.javascript_indent()
--   local line = vim.fn.getline(vim.v.lnum)
--   local prev_line = vim.fn.getline(vim.v.lnum - 1)
--   if line:match("^%s*[%*/]%s*") then
--     if prev_line:match("^%s*%*%s*") then
--       return vim.fn.indent(vim.v.lnum - 1)
--     end
--     if prev_line:match("^%s*/%*%*%s*$") then
--       return vim.fn.indent(vim.v.lnum - 1) + 1
--     end
--   end
--
--   return vim.fn["GetJavascriptIndent"]()
-- end
--
-- vim.cmd([[autocmd FileType javascript setlocal indentexpr=v:lua.javascript_indent()]])
