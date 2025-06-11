local M = {}

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

-- File comparison state
local compare_files = { first = nil, second = nil }

local mark_file_for_compare = function(file_path)
  if compare_files.first == nil then
    compare_files.first = file_path
    vim.notify("First file marked: " .. vim.fn.fnamemodify(file_path, ":t"))
  elseif compare_files.second == nil then
    compare_files.second = file_path
    vim.notify("Second file marked: " .. vim.fn.fnamemodify(file_path, ":t"))
  else
    -- Reset and mark new first file
    compare_files.first = file_path
    compare_files.second = nil
    vim.notify("Reset. First file marked: " .. vim.fn.fnamemodify(file_path, ":t"))
  end
end

local compare_marked_files = function()
  if compare_files.first == nil then
    vim.notify("No files marked for comparison", vim.log.levels.WARN)
    return
  end

  if compare_files.second == nil then
    vim.notify("Only one file marked. Mark a second file to compare.", vim.log.levels.WARN)
    return
  end

  -- Ensure files exist
  if vim.fn.filereadable(compare_files.first) == 0 then
    vim.notify("First file not readable: " .. compare_files.first, vim.log.levels.ERROR)
    return
  end

  if vim.fn.filereadable(compare_files.second) == 0 then
    vim.notify("Second file not readable: " .. compare_files.second, vim.log.levels.ERROR)
    return
  end

  -- Open files in diff mode
  vim.cmd("tabnew")
  vim.cmd("edit " .. vim.fn.fnameescape(compare_files.first))
  vim.cmd("diffthis")
  vim.cmd("vsplit " .. vim.fn.fnameescape(compare_files.second))
  vim.cmd("diffthis")

  vim.notify(
    "Comparing: "
      .. vim.fn.fnamemodify(compare_files.first, ":t")
      .. " ↔ "
      .. vim.fn.fnamemodify(compare_files.second, ":t")
  )

  -- Reset after comparison
  compare_files.first = nil
  compare_files.second = nil
end

local get_compare_status = function()
  if compare_files.first == nil then
    return "No files marked"
  elseif compare_files.second == nil then
    return "First: " .. vim.fn.fnamemodify(compare_files.first, ":t") .. " (mark second file)"
  else
    return "Ready: "
      .. vim.fn.fnamemodify(compare_files.first, ":t")
      .. " ↔ "
      .. vim.fn.fnamemodify(compare_files.second, ":t")
  end
end

M.mark_file_for_compare = mark_file_for_compare
M.compare_marked_files = compare_marked_files
M.get_compare_status = get_compare_status

-- Define user commands
vim.api.nvim_create_user_command(
  "CompareToClipboard",
  compare_to_clipboard,
  { desc = "Compare the current buffer to the clipboard" }
)

return M
