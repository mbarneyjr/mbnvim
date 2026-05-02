local awsuse_dir = vim.fn.expand("~/.aws/awsuse")
local awsuse_config = awsuse_dir .. "/config"
local awsuse_credentials = awsuse_dir .. "/credentials"

local function squishinate()
  vim.fn.mkdir(awsuse_dir, "p")
  vim.fn.system("cat ~/.aws/*config* > " .. awsuse_config)
  vim.fn.system("cat ~/.aws/*credentials* > " .. awsuse_credentials)
end

local function get_profiles()
  squishinate()
  local profiles = {}
  for _, path in ipairs({ awsuse_config, awsuse_credentials }) do
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        local profile = line:match("^%[profile%s+(.-)%]$") or line:match("^%[(.-)%]$")
        if profile then
          profiles[profile] = true
        end
      end
      f:close()
    end
  end
  return vim.tbl_keys(profiles)
end

local regions = {
  "us-east-1",
  "us-east-2",
  "us-west-1",
  "us-west-2",
  "af-south-1",
  "ap-east-1",
  "ap-south-1",
  "ap-south-2",
  "ap-southeast-1",
  "ap-southeast-2",
  "ap-southeast-3",
  "ap-southeast-4",
  "ap-southeast-5",
  "ap-southeast-7",
  "ap-northeast-1",
  "ap-northeast-2",
  "ap-northeast-3",
  "ap-east-2",
  "ca-central-1",
  "ca-west-1",
  "eu-central-1",
  "eu-central-2",
  "eu-west-1",
  "eu-west-2",
  "eu-west-3",
  "eu-south-1",
  "eu-south-2",
  "eu-north-1",
  "il-central-1",
  "mx-central-1",
  "me-south-1",
  "me-central-1",
  "sa-east-1",
}

local function push_credentials(profile, region)
  local creds_json = vim.fn.system({
    "aws",
    "configure",
    "export-credentials",
    "--profile",
    profile,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to get credentials for " .. profile .. ": " .. creds_json, vim.log.levels.ERROR)
    return
  end

  local creds = vim.json.decode(creds_json)
  if not creds or not creds.AccessKeyId then
    vim.notify("Invalid credentials for " .. profile, vim.log.levels.ERROR)
    return
  end

  if not region then
    region = vim.fn.system({ "aws", "configure", "get", "region", "--profile", profile }):gsub("%s+$", "")
    if vim.v.shell_error ~= 0 or region == "" then
      region = "us-east-1"
    end
  end

  -- dispatch to consumers
  local cfn = require("barney.plugins.lsp.cfn")
  cfn.push_credentials(profile, creds.AccessKeyId, creds.SecretAccessKey, creds.SessionToken, region)

  local identity_json = vim.fn.system({
    "aws",
    "sts",
    "get-caller-identity",
    "--profile",
    profile,
  })
  local account_id = ""
  if vim.v.shell_error == 0 then
    local identity = vim.json.decode(identity_json)
    if identity and identity.Account then
      account_id = identity.Account
    end
  end

  vim.notify("AWS credentials set: " .. profile .. " (" .. account_id .. ", " .. region .. ")")
end

local function clear_credentials()
  local cfn = require("barney.plugins.lsp.cfn")
  cfn.clear_credentials()
  vim.notify("AWS credentials cleared")
end

vim.api.nvim_create_user_command("Awsuse", function(opts)
  local profile = opts.fargs[1]
  local region = opts.fargs[2]
  squishinate()
  push_credentials(profile, region)
end, {
  nargs = "+",
  complete = function(_, cmdline)
    local args = vim.split(cmdline, "%s+")
    if #args <= 2 then
      return get_profiles()
    elseif #args == 3 then
      return regions
    end
    return {}
  end,
  desc = "Set AWS credentials",
})

vim.api.nvim_create_user_command("Awsunuse", function()
  clear_credentials()
end, { desc = "Clear AWS credentials" })
