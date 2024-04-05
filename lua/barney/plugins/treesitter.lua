return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "nvim-treesitter/playground",
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")
    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      context_commentstring = {
        enable = false,
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
      -- ensure these language parsers are installed
      ensure_installed = {
        "json",
        "yaml",
        "javascript",
        "jsdoc",
        "typescript",
        "html",
        "python",
        "css",
        "markdown",
        "markdown_inline",
        "bash",
        "lua",
        "dockerfile",
        "gitignore",
        "query",
        "hcl",
        "terraform",
        "dot",
        "make",
        "ini",
        "mermaid",
        "nix",
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
  end,
}
