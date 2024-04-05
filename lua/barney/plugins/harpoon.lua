return {
  "ThePrimeagen/harpoon",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    -- set keymaps
    local key = require("barney.lib.keymap")
    local mark = require("harpoon.mark")
    local ui = require("harpoon.ui")

    local function nav_file(index)
      local function nav()
        ui.nav_file(index)
      end
      return nav
    end

    key.nmap("<leader>ha", mark.add_file, "[h]arpoon [a]dd")
    key.nmap("<leader>hm", ui.toggle_quick_menu, "[h]arpoon [m]enu")
    key.nmap("<leader>h1", nav_file(1), "[h]arpoon 1")
    key.nmap("<leader>h2", nav_file(2), "[h]arpoon 2")
    key.nmap("<leader>h3", nav_file(3), "[h]arpoon 3")
    key.nmap("<leader>h4", nav_file(4), "[h]arpoon 4")
    key.nmap("<leader>h5", nav_file(5), "[h]arpoon 5")
  end,
}
