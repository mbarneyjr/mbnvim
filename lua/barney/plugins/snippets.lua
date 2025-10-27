local luasnip = require("luasnip")

luasnip.add_snippets("all", {
  luasnip.snippet("aws", {
    luasnip.text_node("AWSTemplateFormatVersion: '2010-09-09'"),
  }),
  luasnip.snippet("transform", {
    luasnip.text_node("Transform: AWS::Serverless-2016-10-31"),
  }),
})
