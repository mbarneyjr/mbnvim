local key = require("barney.lib.keymap")
local dap = require("dap")
local dap_utils = require("dap.utils")
local dapui = require("dapui")
local widgets = require("dap.ui.widgets")
local vscode = require("dap.ext.vscode")
local dap_virtual_text = require("nvim-dap-virtual-text")

dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "js-debug",
    args = {
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
