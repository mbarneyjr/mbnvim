vim.filetype.add({
  extension = {
    jsonl = "json",
  },
  pattern = {
    [".*"] = {
      priority = math.huge,
      function(_, bufnr)
        -- check for github actions
        local path = vim.api.nvim_buf_get_name(bufnr)
        if string.find(path, ".github/") then
          return "yaml.github_actions"
        end
        -- check for cloudformation
        local line1 = vim.filetype.getlines(bufnr, 1)
        local line2 = vim.filetype.getlines(bufnr, 2)
        if vim.filetype.matchregex(line1, [[^AWSTemplateFormatVersion]]) then
          return "yaml.cloudformation"
        elseif
          vim.filetype.matchregex(line1, [[["']AWSTemplateFormatVersion]])
          or vim.filetype.matchregex(line2, [[["']AWSTemplateFormatVersion]])
        then
          return "json.cloudformation"
        end
      end,
    },
  },
})
