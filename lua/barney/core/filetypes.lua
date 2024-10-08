vim.filetype.add({
  extension = {
    jsonl = "json",
    tf = "terraform",
  },
  pattern = {
    [".*"] = {
      priority = math.huge,
      function(_, bufnr)
        -- check for github actions
        local path = vim.api.nvim_buf_get_name(bufnr)
        if string.find(path, ".asl.yml") or string.find(path, ".asl.yaml") then
          return "yaml.states"
        end
        if string.find(path, ".asl.json") then
          return "json.states"
        end
        if string.find(path, "docker%-compose") then
          return "yaml.docker-compose"
        end
        if string.find(path, "%.github/workflows") == 1 then
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
        -- check for amazon-states-language
        if vim.filetype.matchregex(line1, [[^StartsAt]]) or vim.filetype.matchregex(line1, [[^Comment]]) then
          return "yaml.states"
        elseif
          vim.filetype.matchregex(line1, [[["']StartsAt]])
          or vim.filetype.matchregex(line1, [[["']Comment]])
          or vim.filetype.matchregex(line2, [[["']StartsAt]])
          or vim.filetype.matchregex(line2, [[["']Comment]])
        then
          return "json.states"
        end
      end,
    },
  },
})
