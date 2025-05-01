local key = require("barney.lib.keymap")
local lsp_file_operations = require("lsp-file-operations")

local lsp_attach = function(_, bufnr)
  key.nmap("gR", vim.lsp.buf.references, "[g]oto LSP [R]eferences", bufnr)
  key.nmap("gd", vim.lsp.buf.definition, "[g]oto LSP [d]efinitions", bufnr)
  key.nmap("<leader>ca", vim.lsp.buf.code_action, "LSP [c]ode [a]ctions", bufnr)
  key.nmap("<leader>cr", vim.lsp.buf.rename, "LSP [c]ode [r]ename", bufnr)
  key.nmap("<leader>dk", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, "goto [d]iagnostic [p]revious", bufnr)
  key.nmap("<leader>dj", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, "goto [d]iagnostic [n]ext", bufnr)
  key.nmap("K", vim.lsp.buf.hover, "LSP documentation", bufnr)
  key.nmap("<leader>rs", ":LspRestart<CR>", "LSP documentation", bufnr)
end
vim.api.nvim_create_autocmd("LspAttach", { callback = lsp_attach })

lsp_file_operations.setup()

vim.lsp.config("*", {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = false,
      },
    },
  },
})

require("barney.plugins.lsp.bash")
require("barney.plugins.lsp.cfn")
require("barney.plugins.lsp.css")
require("barney.plugins.lsp.docker-compose")
require("barney.plugins.lsp.docker")
require("barney.plugins.lsp.dot")
require("barney.plugins.lsp.glsl")
require("barney.plugins.lsp.go")
require("barney.plugins.lsp.html")
require("barney.plugins.lsp.json")
require("barney.plugins.lsp.lua")
require("barney.plugins.lsp.nix")
require("barney.plugins.lsp.python")
require("barney.plugins.lsp.tailwindcss")
require("barney.plugins.lsp.templ")
require("barney.plugins.lsp.ts")
