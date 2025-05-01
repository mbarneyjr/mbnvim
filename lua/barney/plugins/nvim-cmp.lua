local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

require("luasnip.loaders.from_vscode").lazy_load()
vim.keymap.set({ "i", "s" }, "<C-J>", function()
  luasnip.jump(1)
end, { silent = true })
cmp.setup({
  completion = { completeopt = "menu,menuone,preview,noselect" },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-j>"] = cmp.mapping.select_next_item(),
    ["<C-k>"] = cmp.mapping.select_prev_item(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<c-l>"] = cmp.mapping.confirm({ select = false }),
    ["<C-e>"] = cmp.mapping.close(),
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-n>"] = cmp.mapping.scroll_docs(4),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp", priority = 100 },
    { name = "path", priority = 90 },
    { name = "copilot", priority = 70 },
    { name = "supermaven", priority = 60 },
    { name = "luasnip", priority = 50 },
    { name = "buffer", priority = 10 },
  }),
  window = {
    completion = { border = "rounded" },
    documentation = { border = "rounded" },
  },
})

luasnip.add_snippets("all", {
  luasnip.snippet("aws", {
    luasnip.text_node("AWSTemplateFormatVersion: '2010-09-09'"),
  }),
  luasnip.snippet("transform", {
    luasnip.text_node("Transform: AWS::Serverless-2016-10-31"),
  }),
  -- create a node:test test file snippet
  luasnip.snippet("nodetestfile", {
    luasnip.text_node({
      "import { describe, it, beforeEach, afterEach, mock } from 'node:test';",
      "import assert from 'node:assert/strict';",
      "",
      "await describe('",
    }),
    luasnip.insert_node(1),
    luasnip.text_node({
      "', async () => {",
      "  beforeEach(() => {",
      "    mock.reset();",
      "  });",
      "  afterEach(() => {",
      "    mock.restoreAll();",
      "  });",
      "",
      "  await it('",
    }),
    luasnip.insert_node(2),
    luasnip.text_node({
      "', async () => {",
      "    ",
    }),
    luasnip.insert_node(3),
    luasnip.text_node({
      "",
      "  });",
      "});",
    }),
  }),
  -- a /** type comment snippet
  luasnip.snippet("/**", {
    luasnip.text_node({
      "/** @type {",
    }),
    luasnip.insert_node(1),
    luasnip.text_node({
      "} */",
    }),
  }),
  -- esmodules dirname snippet
  luasnip.snippet("dirname", {
    luasnip.text_node({
      "import * as url from 'url';",
      "const dirname = url.fileURLToPath(new URL('.', import.meta.url));",
    }),
  }),
  -- create a node:test individual test snippet
  luasnip.snippet("nodetest", {
    luasnip.text_node({
      "  await it('",
    }),
    luasnip.insert_node(1),
    luasnip.text_node({
      "', async () => {",
      "    ",
    }),
    luasnip.insert_node(2),
    luasnip.text_node({
      "",
      "  });",
    }),
  }),
})

vim.lsp.config("*", {
  capabilities = cmp_nvim_lsp.default_capabilities(),
})
