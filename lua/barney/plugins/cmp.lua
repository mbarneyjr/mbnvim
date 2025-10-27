local blink = require("blink.cmp")
blink.setup({
  keymap = {
    preset = "default",
    ["<C-space>"] = { "show" },
    ["<C-j>"] = { "select_next" },
    ["<C-k>"] = { "select_prev" },
    ["<C-l>"] = { "accept", "fallback" },
  },
  cmdline = {
    keymap = { preset = "inherit" },
    completion = { menu = { auto_show = true } },
  },
  snippets = { preset = "luasnip" },
  sources = {
    default = { "lsp", "path", "snippets", "copilot" },
    providers = {
      copilot = {
        name = "copilot",
        module = "blink-copilot",
        score_offset = 100,
        async = true,
      },
    },
  },
  completion = {
    documentation = {
      auto_show = true,
    },
    menu = {
      draw = {
        columns = { { "label", "kind", gap = 1 } },
      },
    },
  },
  signature = {
    enabled = true,
  },
})
