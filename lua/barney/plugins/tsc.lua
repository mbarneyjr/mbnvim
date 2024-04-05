return {
  "dmmulroy/tsc.nvim",
  dependencies = { "dmmulroy/ts-error-translator.nvim" },
  ft = { "typescript", "javascript" },
  config = function()
    local tsc = require("tsc")
    local ts_error_translator = require("ts-error-translator")
    tsc.setup()
    ts_error_translator.setup()
  end,
}
