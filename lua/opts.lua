vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.wrap = false
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.smartindent = true
vim.o.swapfile = false
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.cursorcolumn = false
vim.o.incsearch = true
vim.o.updatetime = 1000
vim.g.mapleader = " "
vim.o.winborder = "rounded"

-- clipboard: OSC52 when in a real terminal, silent on TTY
if vim.env.TERM ~= "linux" and vim.env.TERM ~= "" then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
else
  vim.o.clipboard = ""
end
