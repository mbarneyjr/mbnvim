return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    local telescope_builtins = require("telescope.builtin")
    local key = require("barney.lib.keymap")

    local lsp_attach = function(_, bufnr)
      key.nmap("gR", telescope_builtins.lsp_references, "[g]oto LSP [R]eferences", bufnr)
      key.nmap("gd", telescope_builtins.lsp_definitions, "[g]oto LSP [d]efinitions", bufnr)
      key.nmap("<leader>ca", vim.lsp.buf.code_action, "LSP [c]ode [a]ctions", bufnr)
      key.nmap("<leader>cr", vim.lsp.buf.rename, "LSP [c]ode [r]ename", bufnr)
      key.nmap("<leader>dk", vim.diagnostic.goto_prev, "goto [d]iagnostic [p]revious", bufnr)
      key.nmap("<leader>dj", vim.diagnostic.goto_next, "goto [d]iagnostic [n]ext", bufnr)
      key.nmap("K", vim.lsp.buf.hover, "LSP documentation", bufnr)
      key.nmap("<leader>rs", ":LspRestart<CR>", "LSP documentation", bufnr)
    end
    vim.api.nvim_create_autocmd("LspAttach", { callback = lsp_attach })
  end,
}
