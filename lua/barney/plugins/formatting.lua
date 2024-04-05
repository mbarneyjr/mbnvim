return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")
    local key = require("barney.lib.keymap")
    conform.setup({
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        markdown = { "prettier" },
        terraform = { "terraform_fmt" },
        ["*"] = { "trim_whitespace" },
      },

      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        -- Disable autoformat for files in a certain path
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/node_modules/") then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    })

    local format = function()
      conform.format({
        lsp_fallback = true,
        -- async = false,
        timeout_ms = 500,
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
    vim.api.nvim_create_user_command(
      "AutoFormattingToggle",
      toggle_formatting,
      { desc = "Toggle Conform autoformatting" }
    )
    key.nmap("<leader>ft", toggle_formatting, "[t]oggle auto[f]ormatting")
  end,
}
