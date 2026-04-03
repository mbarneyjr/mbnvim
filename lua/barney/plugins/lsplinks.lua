local lsplinks = require("lsplinks")
lsplinks.setup()

vim.keymap.set("n", "gx", function()
  local urls = {}

  -- get lsplinks document link under cursor
  local link = lsplinks.current()
  if link then
    table.insert(urls, link)
  end

  -- get default urls (extmarks, cfile, etc.)
  for _, url in ipairs(require("vim.ui")._get_urls()) do
    if not vim.tbl_contains(urls, url) then
      table.insert(urls, url)
    end
  end

  if #urls == 0 then
    return
  elseif #urls == 1 then
    lsplinks.open(urls[1])
  else
    vim.ui.select(urls, { prompt = "Open URL:" }, function(choice)
      if choice then
        lsplinks.open(choice)
      end
    end)
  end
end, { desc = "Open URL (with selection if multiple)" })
