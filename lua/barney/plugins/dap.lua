--- Gets a path to a package in the Mason registry.
--- Prefer this to `get_package`, since the package might not always be
--- available yet and trigger errors.
---@param pkg string
---@param path? string
local function get_pkg_path(pkg, path)
  pcall(require, "mason")
  local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
  path = path or ""
  local ret = root .. "/packages/" .. pkg .. "/" .. path
  return ret
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "jay-babu/mason-nvim-dap.nvim",
    "theHamsta/nvim-dap-virtual-text",
    "nvim-telescope/telescope-dap.nvim",
    "nvim-neotest/nvim-nio",
    -- {
    --   "mxsdev/nvim-dap-vscode-js",
    --   opts = {
    --     debugger_path = string.format("%s/vscode-js-debug/", vim.fn.stdpath("data") .. "/lazy"),
    --     adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost", "node" },
    --     node_path = "node",
    --   },
    -- },
    -- {
    --   "microsoft/vscode-js-debug",
    --   build = "npm ci --legacy-peer-deps && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
    --   tag = "v1.97.1",
    -- },
  },
  config = function()
    local dap = require("dap")
    local dap_utils = require("dap.utils")
    local dapui = require("dapui")
    local widgets = require("dap.ui.widgets")
    local mason_nvim_dap = require("mason-nvim-dap")
    local key = require("barney.lib.keymap")
    local vscode = require("dap.ext.vscode")
    local dap_virtual_text = require("nvim-dap-virtual-text")
    local telescope = require("telescope")

    telescope.load_extension("dap")
    mason_nvim_dap.setup({
      automatic_installation = true,
      ensure_installed = {},
      handlers = {
        function(config)
          require("mason-nvim-dap").default_setup(config)
        end,
      },
    })

    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
          "${port}",
        },
      },
    }
    dap.configurations.javascript = {
      {
        type = "pwa-node",
        request = "launch",
        name = "JS: Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "JS: Attach",
        processId = function()
          return dap_utils.pick_process({
            filter = "--inspect",
          })
        end,
        cwd = "${workspaceFolder}",
      },
    }
    dap.configurations.typescript = {
      {
        type = "pwa-node",
        request = "launch",
        name = "TSX: Launch file",
        program = "${file}",
        runtimeExecutable = "npx",
        runtimeArgs = { "tsx" },
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "TS: Launch file",
        program = "${file}",
        runtimeArgs = { "--require", "ts-node/register" },
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "TS: Attach",
        processId = function()
          return dap_utils.pick_process({
            filter = "--inspect",
          })
        end,
        cwd = "${workspaceFolder}",
      },
    }

    vscode.load_launchjs(nil, {
      ["pwa-node"] = { "javascript", "typescript" },
      ["node"] = { "javascript", "typescript" },
    })

    require("dapui").setup({
      layouts = {
        {
          elements = {
            { id = "scopes", size = 1 },
          },
          size = 0.25,
          position = "right",
        },
        {
          elements = {
            { id = "repl", size = 1 },
          },
          size = 0.27,
          position = "bottom",
        },
      },
    })

    dap_virtual_text.setup()

    -- set custom signs
    vim.fn.sign_define(
      "DapBreakpoint",
      { text = "●", texthl = "DiagnosticError", linehl = "DiagnosticError", numhl = "DiagnosticError" }
    )
    vim.fn.sign_define(
      "DapBreakpointCondition",
      { text = "●", texthl = "DiagnosticInfo", linehl = "DiagnosticInfo", numhl = "DiagnosticInfo" }
    )
    vim.fn.sign_define(
      "DapLogPoint",
      { text = "⁉", texthl = "DiagnosticInfo", linehl = "DiagnosticInfo", numhl = "DiagnosticInfo" }
    )
    vim.fn.sign_define(
      "DapStopped",
      { text = "→", texthl = "DiagnosticWarn", linehl = "DiagnosticWarn", numhl = "DiagnosticWarn" }
    )
    vim.fn.sign_define(
      "DapBreakpointRejected",
      { text = "✗", texthl = "DiagnosticError", linehl = "DiagnosticError", numhl = "DiagnosticError" }
    )

    -- keymaps
    local log_breakpoint = function()
      vim.ui.input({ prompt = "Log point message: " }, function(message)
        dap.set_breakpoint(nil, nil, message)
      end)
    end

    key.nmap("<leader>db", dap.toggle_breakpoint, "toggle [d]ebugger [b]reakpoint")
    key.nmap("<leader>dL", log_breakpoint, "toggle [d]ebugger [L]og breakpoint")
    key.nmap("<leader>dc", dap.continue, "[d]ebugger [c]ontinue")
    key.nmap("<leader>dC", dap.clear_breakpoints, "[d]ebugger [C]lear breakpoints")
    key.nmap("<leader>dn", dap.run_to_cursor, "[d]ebugger ru[n] to cursor")
    key.nmap("<leader>do", dap.step_over, "[d]ebugger step [o]ver")
    key.nmap("<leader>di", dap.step_into, "[d]ebugger step [i]nto")
    key.nmap("<leader>dO", dap.step_out, "[d]ebugger step [O]ut")
    key.nmap("<Leader>dr", dap.repl.toggle, "[d]ebugger [r]epl")
    key.nmap("<leader>dh", widgets.hover, "[d]ebug [h]over")
    key.nmap("<leader>dH", widgets.preview, "[d]ebug [p]review")
    key.nmap("<leader>df", dapui.float_element, "[d]ebug ui [f]float")
    key.nmap("<leader>du", dapui.toggle, "toggle [d]ebgger [u]ser interface")
  end,
}
