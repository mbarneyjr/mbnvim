return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "marilari88/twoslash-queries.nvim",
    { "folke/neodev.nvim", config = true },
  },
  config = function()
    local neodev = require("neodev")
    local lspconfig = require("lspconfig")
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local mason_tool_installer = require("mason-tool-installer")

    mason.setup({
      ui = {
        border = "rounded",
      },
    })
    mason_lspconfig.setup({
      ensure_installed = {
        "tsserver",
        "html",
        "cssls",
        "lua_ls",
        "docker_compose_language_service",
        "dockerls",
        "dotls",
        "jsonls",
        "terraformls",
        "pyright",
        "templ",
        "nil_ls",
      },
      automatic_installation = true,
    })

    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local lsp_settings = require("barney.lib.lsp_settings")

    local configs = require("lspconfig.configs")

    neodev.setup()

    -- setup mason-managed servers
    mason_lspconfig.setup_handlers({
      function(server_name)
        local default_capabilities = cmp_nvim_lsp.default_capabilities()
        local capabilities = vim.tbl_extend(
          "force",
          default_capabilities,
          lsp_settings[server_name] and lsp_settings[server_name].capabilities or {},
          -- fsevents high cpu bug
          {
            workspace = {
              didChangeWatchedFiles = {
                dynamicRegistration = false,
              },
            },
          }
        )
        lspconfig[server_name].setup({
          capabilities = capabilities,
          settings = lsp_settings[server_name] and lsp_settings[server_name].settings,
          on_attach = lsp_settings[server_name] and lsp_settings[server_name].on_attach,
        })
      end,
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettier",
        "stylua",
        "eslint-lsp",
        "eslint_d",
        "nixpkgs-fmt",
      },
    })

    -- setup cfn-lsp-extra
    if not configs["cfn-lsp-extra"] then
      configs["cfn-lsp-extra"] = {
        default_config = {
          cmd = { "cfn-lsp-extra" },
          filetypes = { "yaml.cloudformation", "json.cloudformation" },
          root_dir = function(fname)
            return lspconfig.util.find_git_ancestor(fname)
          end,
          settings = { validate = false },
        },
      }
    end
    lspconfig["cfn-lsp-extra"].setup({})
  end,
}
