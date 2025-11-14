require("avante_lib").load()
require("avante").setup({
  provider = "bedrock",
  providers = {
    bedrock = {
      model = "global.anthropic.claude-haiku-4-5-20251001-v1:0",
      aws_profile = "claude",
      aws_region = "us-east-2",
    },
  },
})
