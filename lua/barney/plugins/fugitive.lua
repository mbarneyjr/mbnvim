local key = require("barney.lib.keymap")
local function toggle_fugitive()
  -- get fugitive buffer
  local buffers = vim.api.nvim_list_bufs()
  -- find buffer with fugitive://
  local bufnr = vim.tbl_filter(function(buf)
    local bufname = vim.api.nvim_buf_get_name(buf)
    return bufname:match("fugitive://")
  end, buffers)[1]

  if not bufnr then
    vim.cmd("G")
    return
  end

  -- list windows
  local windows = vim.api.nvim_list_wins()
  -- find windows with fugitive buffer
  local fugitive_windows = vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_buf(win) == bufnr
  end, windows)
  -- close fugitive windows
  for _, win in ipairs(fugitive_windows) do
    vim.api.nvim_win_close(win, true)
  end
  -- close fugitive buffer
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

key.nmap("gD", ":Gvdiffsplit!<CR>", "git diff conflict")
key.nmap("<c-g>", toggle_fugitive, "Toggle vim-fugitive")
key.nmap("<leader>gs", toggle_fugitive, "Toggle vim-fugitive")
key.nmap("<leader>gl", ":Flog<CR>", "Toggle vim-fugitive")
vim.cmd(":set diffopt=filler,context:1000000,vertical")
vim.cmd(":set fillchars=diff:\\ ")
vim.cmd(":autocmd FileType git set foldmethod=syntax")

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
