local function get_github_token()
  local handle = io.popen("gh auth token 2>/dev/null")
  if not handle then return nil end
  local token = handle:read("*a"):gsub("%s+", "")
  handle:close()
  return token ~= "" and token or nil
end

local function parse_github_remote(url)
  if not url or url == "" then return nil end
  local owner, repo = url:match("git@github%.com:([^/]+)/([^/%.]+)")
  if owner and repo then return owner, repo:gsub("%.git$", "") end
  owner, repo = url:match("github%.com/([^/]+)/([^/%.]+)")
  if owner and repo then return owner, repo:gsub("%.git$", "") end
  return nil
end

local function get_repo_info(owner, repo)
  local cmd = string.format(
    "gh repo view %s/%s --json id,owner --template '{{.id}}\t{{.owner.type}}' 2>/dev/null",
    owner, repo
  )
  local handle = io.popen(cmd)
  if not handle then return nil end
  local result = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  local id, owner_type = result:match("^(%d+)\t(.+)$")
  if id then
    return { id = tonumber(id), organizationOwned = owner_type == "Organization" }
  end
  return nil
end

local function get_repos_config()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if not handle then return nil end
  local git_root = handle:read("*a"):gsub("%s+", "")
  handle:close()
  if git_root == "" then return nil end

  handle = io.popen("git remote get-url origin 2>/dev/null")
  if not handle then return nil end
  local remote_url = handle:read("*a"):gsub("%s+", "")
  handle:close()

  local owner, name = parse_github_remote(remote_url)
  if not owner or not name then return nil end

  local info = get_repo_info(owner, name)
  return {
    {
      id = info and info.id or 0,
      owner = owner,
      name = name,
      organizationOwned = info and info.organizationOwned or false,
      workspaceUri = "file://" .. git_root,
    },
  }
end

local function get_init_options()
  return {
    sessionToken = get_github_token(),
    repos = get_repos_config(),
  }
end

vim.lsp.config("actionsls", {
  cmd = { "actions-languageserver", "--stdio" },
  filetypes = { "yaml.github_actions" },
  capabilities = {
    workspace = {
      didChangeWorkspaceFolders = {
        dynamicRegistration = false,
      },
    },
  },
  init_options = get_init_options(),
})
vim.lsp.enable("actionsls")

-- Refresh token and repo config when actionsls restarts (e.g. via :LspRestart)
vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "actionsls" then
      vim.lsp.config("actionsls", { init_options = get_init_options() })
    end
  end,
})
