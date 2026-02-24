local function json_root_keys(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  local keys = {}
  for k in pairs(decoded) do
    keys[k] = true
  end
  return keys
end

local function yaml_root_keys(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, "yaml")
  if not ok then
    return {}
  end
  local trees = parser:parse()
  if not trees or not trees[1] then
    return {}
  end
  local root = trees[1]:root()
  local query_ok, query = pcall(
    vim.treesitter.query.parse,
    "yaml",
    "(stream (document (block_node (block_mapping (block_mapping_pair key: (_) @key)))))"
  )
  if not query_ok then
    return {}
  end
  local keys = {}
  for _, node in query:iter_captures(root, content) do
    keys[vim.treesitter.get_node_text(node, content)] = true
  end
  return keys
end

vim.treesitter.language.register("yaml", "yaml.states")
vim.treesitter.language.register("yaml", "yaml.cloudformation")
vim.treesitter.language.register("json", "json.states")
vim.treesitter.language.register("json", "json.cloudformation")

vim.filetype.add({
  extension = {
    jsonl = "json",
    tf = "terraform",
    tofu = "terraform",
    cfnlintrc = "yaml",
  },
  pattern = {
    [".env.*"] = "sh",
    [".*"] = {
      priority = math.huge,
      function(_, bufnr)
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
        if string.find(path, "%.github/workflows") then
          return "yaml.github_actions"
        end
        -- parse root keys to detect cloudformation and states
        local ext = vim.fn.fnamemodify(path, ":e")
        if ext == "json" then
          local keys = json_root_keys(bufnr)
          if keys["AWSTemplateFormatVersion"] then
            return "json.cloudformation"
          end
          if keys["StartsAt"] or keys["Comment"] then
            return "json.states"
          end
        elseif ext == "yaml" or ext == "yml" then
          local keys = yaml_root_keys(bufnr)
          if keys["AWSTemplateFormatVersion"] then
            return "yaml.cloudformation"
          end
          if keys["StartsAt"] or keys["Comment"] then
            return "yaml.states"
          end
        end
      end,
    },
  },
})
