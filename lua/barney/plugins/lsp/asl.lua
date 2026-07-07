vim.lsp.config("asl_lsp", {
  cmd = { "asl-language-server", "--stdio" },
  filetypes = { "json.states", "yaml.states" },
  root_markers = { ".git" },
  get_language_id = function(_, filetype)
    if filetype == "yaml.states" then
      return "asl-yaml"
    end
    return "asl"
  end,
  init_options = {
    provideFormatter = true,
  },
  settings = {
    aws = {
      stepfunctions = {
        asl = {
          resultLimit = 5000,
        },
      },
    },
  },
})
vim.lsp.enable("asl_lsp")
