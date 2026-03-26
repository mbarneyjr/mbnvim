local lsplinks = require("lsplinks")
lsplinks.setup()
vim.keymap.set("n", "gx", lsplinks.gx)
vim.notify(vim.inspect(lsplinks))
