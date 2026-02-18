local key = require("barney.lib.keymap")
local dap = require("dap")
local dap_utils = require("dap.utils")
local dapview = require("dap-view")
local widgets = require("dap.ui.widgets")
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
    outputCapture = "std",
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
    outputCapture = "std",
    cwd = "${workspaceFolder}",
  },
}
dap.configurations.typescript = dap.configurations.javascript

dapview.setup({
  winbar = {
    controls = {
      enabled = true,
    },
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
    default_section = "scopes",
  },
  auto_toggle = true,
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
key.nmap("<leader>du", dapview.toggle, "toggle [d]ebgger [u]ser interface")
