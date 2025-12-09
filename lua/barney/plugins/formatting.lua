local conform = require("conform")
local key = require("barney.lib.keymap")

require("conform").formatters["biome-check"] = {
  append_args = { "--indent-style", "space" },
}

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "golangci-lint" },
    javascript = { "biome-check" },
    typescript = { "biome-check" },
    javascriptreact = { "biome-check" },
    typescriptreact = { "biome-check" },
    json = { "biome-check" },
    jsonc = { "biome-check" },
    css = { "biome-check" },
    markdown = { "prettier" },
    terraform = { "terraform_fmt" },
    python = { "black", "usort" },
    ["*"] = { "trim_whitespace", "trim_newlines" },
    nix = { "nixfmt" },
  },

  format_on_save = function(bufnr)
    -- Disable with a global or buffer-local variable
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    -- Disable autoformat for files in a certain path
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname:match("/.venv/") then
      return
    end
    if bufname:match("/node_modules/") then
      return
    end
    return {
      lsp_format = "first",
      timeout_ms = 2000,
    }
  end,
})

local format = function()
  vim.notify("Formatted file")
  conform.format({
    lsp_format = "first",
    timeout_ms = 1000,
  })
end
vim.api.nvim_create_user_command("Format", format, { desc = "Format buffer with Conform" })
key.nmap("<leader>cf", format, "[code] [f]ormatter")

local toggle_formatting = function()
  if vim.g.disable_autoformat == true then
    vim.g.disable_autoformat = false
    vim.notify("Autoformatting enabled")
  else
    vim.g.disable_autoformat = true
    vim.notify("Autoformatting disabled")
  end
end
vim.api.nvim_create_user_command("AutoFormattingToggle", toggle_formatting, { desc = "Toggle Conform autoformatting" })
key.nmap("<leader>ft", toggle_formatting, "[t]oggle auto[f]ormatting")
