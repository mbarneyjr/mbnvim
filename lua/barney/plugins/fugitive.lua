local key = require("barney.lib.keymap")

local function toggle_fugitive()
  local buffers = vim.api.nvim_list_bufs()
  local bufnr = vim.tbl_filter(function(buf)
    local bufname = vim.api.nvim_buf_get_name(buf)
    return bufname:match("fugitive://")
  end, buffers)[1]

  if not bufnr then
    vim.cmd("G")
    return
  end

  local windows = vim.api.nvim_list_wins()
  local fugitive_windows = vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_buf(win) == bufnr
  end, windows)
  for _, win in ipairs(fugitive_windows) do
    vim.api.nvim_win_close(win, true)
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function review_branch_diff()
  local branches = vim.fn.systemlist("git branch --all --format='%(refname:short)'")
  branches = vim.tbl_filter(function(branch)
    return branch ~= "" and not branch:match("HEAD")
  end, branches)

  vim.ui.select(branches, { prompt = "Diff against branch:" }, function(branch)
    if not branch then
      return
    end
    vim.cmd("G difftool -y HEAD..." .. branch)
  end)
end

key.nmap("gD", ":Gvdiffsplit!<CR>", "git diff conflict")
key.nmap("<c-g>", toggle_fugitive, "Toggle vim-fugitive")
key.nmap("<leader>gs", toggle_fugitive, "Toggle vim-fugitive")
key.nmap("<leader>gl", ":Flog<CR>", "Toggle vim-fugitive")
key.nmap("<leader>gr", review_branch_diff, "git review: difftool against selected branch")
vim.cmd(":set diffopt=filler,context:1000000,vertical")
vim.cmd(":set fillchars=diff:\\ ")
vim.cmd(":autocmd FileType git set foldmethod=syntax")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function(event)
    local original = vim.fn.maparg("<CR>", "n", false, true)
    local command = original.rhs:gsub("<SID>", "<SNR>" .. original.sid .. "_"):match("^:<C%-U>(.*)<CR>$")
    vim.keymap.set("n", "<CR>", function()
      vim.cmd(command)
      if vim.api.nvim_buf_get_name(0):match("^fugitive://.*//[0-9a-f]+/") then
        local line = vim.fn.line(".")
        vim.cmd("Gedit")
        pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
      end
    end, { buffer = event.buf, desc = "Open work tree file" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "floggraph",
  callback = function(event)
    vim.keymap.set("n", "<CR>", ":Flogsplitcommit<CR> | :resize 10<CR>", { buffer = event.buf })
  end,
})

-- Add gitcommit keymap for claude-commit
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function(event)
    vim.keymap.set("n", "cc", function()
      local output = vim.fn.system("git claude-commit")
      vim.api.nvim_buf_set_lines(event.buf, 0, 1, false, { vim.split(output, "\n")[1] })
    end, { buffer = event.buf, desc = "Use claude-commit to generate commit message" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "floggraph",
  callback = function(event)
    vim.keymap.set("n", "<CR>", ":Flogsplitcommit<CR> | :resize 10<CR>", { buffer = event.buf })
  end,
})
