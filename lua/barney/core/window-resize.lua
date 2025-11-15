local key = require("barney.lib.keymap")

local resize = function(dir)
  local current_win = vim.api.nvim_get_current_win()
  local h_increment = math.floor(vim.o.columns * 0.25)
  local v_increment = math.floor(vim.o.lines * 0.25)

  if dir == "right" then
    vim.cmd("wincmd l")
    vim.cmd("vertical resize -" .. h_increment)
  elseif dir == "left" then
    vim.cmd("wincmd h")
    vim.cmd("vertical resize -" .. h_increment)
  elseif dir == "up" then
    vim.cmd("wincmd k")
    vim.cmd("resize -" .. v_increment)
  elseif dir == "down" then
    vim.cmd("wincmd j")
    vim.cmd("resize -" .. v_increment)
  end

  vim.api.nvim_set_current_win(current_win)
end

key.nmap("<C-M-h>", function()
  resize("left")
end, "Resize window left")
key.tmap("<C-M-h>", function()
  resize("left")
end, "Resize window left")

key.nmap("<C-M-l>", function()
  resize("right")
end, "Resize window right")
key.tmap("<C-M-l>", function()
  resize("right")
end, "Resize window right")

key.nmap("<C-M-k>", function()
  resize("up")
end, "Resize window up")
key.tmap("<C-M-k>", function()
  resize("up")
end, "Resize window up")

key.nmap("<C-M-j>", function()
  resize("down")
end, "Resize window down")
key.tmap("<C-M-j>", function()
  resize("down")
end, "Resize window down")
