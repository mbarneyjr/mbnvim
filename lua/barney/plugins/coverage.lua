return {
  "andythigpen/nvim-coverage",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local key = require("barney.lib.keymap")
    local enable_coverage_watcher = function()
      local coverage = require("coverage")
      coverage.load(true)
      coverage.show()
    end
    key.nmap("<leader>cc", enable_coverage_watcher, "[c]ode [c]overage")
  end,
}
