return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "marilari88/twoslash-queries.nvim",
    { "folke/neodev.nvim", config = true },
    {
      "aws/aws-toolkit-vscode",
      build = "npm ci", -- this project has a postinstall that does the build
      tag = "toolkit/v3.25.0",
    },
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
    local lsp_servers = {
      "ts_ls",
      "html",
      "gopls",
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
      "bashls",
      "tailwindcss",
      "glsl_analyzer",
    }
    mason_lspconfig.setup({
      ensure_installed = lsp_servers,
      automatic_installation = true,
    })

    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local lsp_settings = require("barney.lib.lsp_settings")

    local configs = require("lspconfig.configs")

    neodev.setup()

    -- for each server, setup the server with the settings from the lsp_settings table
    for _, server_name in ipairs(lsp_servers) do
      local default_capabilities = cmp_nvim_lsp.default_capabilities()
      local settings = lsp_settings[server_name]
      local capabilities = vim.tbl_extend(
        "force",
        default_capabilities,
        settings and settings.capabilities or {},
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
        -- vim.lsp.start_client options
        cmd = settings and settings.cmd,
        cmd_cwd = settings and settings.cmd_cwd,
        cmd_env = settings and settings.cmd_env,
        detached = settings and settings.detached,
        workspace_folders = settings and settings.workspace_folders,
        capabilities = capabilities,
        handlers = settings and settings.handlers,
        settings = settings and settings.settings,
        commands = settings and settings.commands,
        init_options = settings and settings.init_options,
        on_error = settings and settings.on_error,
        before_init = settings and settings.before_init,
        on_init = settings and settings.on_init,
        on_exit = settings and settings.on_exit,
        on_attach = settings and settings.on_attach,
        flags = settings and settings.flags,
        -- lspconfig.setup options
        root_dir = settings and settings.root_dir,
        filetypes = settings and settings.filetypes,
        autostart = settings and settings.autostart,
        single_file_support = settings and settings.single_file_support,
        on_new_config = settings and settings.on_new_config,
      })
    end

    mason_tool_installer.setup({
      ensure_installed = {
        "actionlint",
        "prettier",
        "stylua",
        "nixpkgs-fmt",
        "black",
        "js-debug-adapter",
      },
    })

    -- setup amazon-states-language-service
    if not configs["amazon-states-language-service"] then
      configs["amazon-states-language-service"] = {
        default_config = {
          cmd = {
            "node",
            vim.fn.stdpath("data") .. "/lazy/aws-toolkit-vscode/packages/core/dist/src/stepFunctions/asl/aslServer.js",
            "--stdio",
          },
          filetypes = { "yaml.states", "json.states" },
          root_dir = function(fname)
            return lspconfig.util.find_git_ancestor(fname)
          end,
          settings = { validate = false },
        },
      }
    end
    lspconfig["amazon-states-language-service"].setup({
      get_language_id = function(_, ftype)
        if ftype == "yaml.states" then
          return "asl-yaml"
        else
          return "asl"
        end
      end,
      capabilities = {
        textDocument = {
          completion = {
            completionItem = {
              snippetSupport = true,
            },
          },
          rangeFormatting = {
            dynamicRegistration = true,
          },
        },
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
