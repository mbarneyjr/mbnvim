local compare_to_clipboard = function()
  -- Save current buffer info
  local original_buf = vim.api.nvim_get_current_buf()
  local ftype = vim.bo.filetype

  -- Create vertical split with new buffer
  vim.cmd("vsplit")
  vim.cmd("enew")

  -- Set up the clipboard buffer
  local clipboard_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(clipboard_buf, "clipboard")
  vim.bo[clipboard_buf].buftype = "nofile"
  vim.bo[clipboard_buf].bufhidden = "wipe"
  vim.bo[clipboard_buf].swapfile = false
  vim.bo[clipboard_buf].filetype = ftype

  -- Paste clipboard contents
  vim.cmd("put +")
  vim.cmd('normal! gg"_dd') -- Remove empty first line from put without affecting clipboard

  -- Enable diff mode for clipboard buffer
  vim.cmd("diffthis")

  -- Switch back to original buffer and enable diff
  vim.cmd("wincmd h")
  vim.cmd("diffthis")

  vim.cmd("wincmd l")
  -- Set up autocmd to clean up diff mode when closing
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = clipboard_buf,
    once = true,
    callback = function()
      -- Find windows showing the original buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == original_buf then
          vim.api.nvim_win_call(win, function()
            vim.cmd("diffoff")
          end)
        end
      end
    end,
  })
end

-- define user command for compare_to_clipboard
vim.api.nvim_create_user_command(
  "CompareToClipboard",
  compare_to_clipboard,
  { desc = "Compare the current buffer to the clipboard" }
)
