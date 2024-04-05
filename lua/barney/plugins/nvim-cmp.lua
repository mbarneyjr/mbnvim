return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    require("luasnip.loaders.from_vscode").lazy_load()

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
    })
  end,
}
